defmodule DelegaWeb.SlashController do
  use DelegaWeb, :controller

  alias Delega.{Repo, Team, Todo, UserCache, TodoChannel, TodoAssignment}
  alias Delega.Slack.{Renderer, Interactive, Commands}

  import Slack.Messaging

  def parse_user_token(user_token) do
    user_token
    |> String.trim()
    |> String.trim_leading("<@")
    |> String.trim_trailing(">")
    |> String.split("|")
    |> hd
  end

  def interactivity(conn, params) do
    payload = Jason.decode!(Map.get(params, "payload"))

    IO.inspect(payload)

    Interactive.process_interaction(payload)

    conn |> send_resp(200, "")
  end

  def slash(conn, %{"text" => "help"}) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Renderer.render_help()
    })
  end

  def slash(conn, %{"text" => "feedback " <> feedback, "user_id" => user_id}) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Commands.feedback(user_id, feedback)
    })
  end

  def slash(conn, %{
        "text" => "todo",
        "user_id" => user_id
      }) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Commands.todo(user_id)
    })
  end

  def slash(conn, %{"text" => "todo " <> channel_token, "user_id" => user_id}) do
    channel_id = Slack.API.parse_channels(channel_token) |> hd

    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Commands.list_todo_channel(user_id, channel_id)
    })
  end

  def slash(conn, %{"text" => "list", "user_id" => user_id}) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Commands.created_list(user_id)
    })
  end

  def slash(conn, %{"text" => "list " <> channel_token}) do
    channel_id = Slack.API.parse_channels(channel_token) |> hd

    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Commands.list_channel(channel_id)
    })
  end

  def slash(conn, %{
        "text" => "me " <> text,
        "command" => command,
        "team_id" => team_id,
        "user_id" => created_user_id
      }) do
    slash(conn, %{
      "text" => Renderer.escape_user_id(created_user_id) <> " " <> text,
      "command" => command,
      "team_id" => team_id,
      "user_id" => created_user_id
    })
  end

  def slash(conn, %{
        "text" => "<@" <> text,
        "command" => command,
        "team_id" => team_id,
        "user_id" => created_user_id
      }) do
    user_token =
      text
      |> String.trim()
      |> String.split()
      |> hd

    user_id = parse_user_token(user_token)

    todo_msg =
      text
      |> String.trim_leading(user_token <> " ")

    channels = Slack.API.parse_channels(todo_msg)
    todo_msg = Slack.API.trim_channels(todo_msg)

    %{access_token: access_token} = team = Repo.get!(Team, team_id)

    user_id_valid? = UserCache.validate_and_welcome(user_id, team)
    created_user_id_valid? = UserCache.validate_and_welcome(created_user_id, team)

    if user_id_valid? and created_user_id_valid? do
      todo = %Todo{
        team_id: team_id,
        assigned_user_id: user_id,
        created_user_id: created_user_id,
        todo: todo_msg
      }

      case Repo.insert(todo, returning: true) do
        {:ok, todo} ->
          channels
          |> Enum.map(fn channel_id ->
            TodoChannel.insert(todo.todo_id, channel_id)
          end)

          # Add initial assignments
          %TodoAssignment{
            assigned_by_user_id: created_user_id,
            assigned_to_user_id: user_id
          }
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:todo, todo)
          |> Repo.insert!()

          # Get Todo with all associations
          todo = Todo.get_with_assoc(todo.todo_id)

          channels
          |> Enum.map(fn channel_id ->
            Task.start(fn ->
              Slack.API.post_message(%{
                token: access_token,
                channel: channel_id,
                text: "<@#{created_user_id}> has added a new todo.",
                blocks: Renderer.render_todo(todo)
              })
            end)
          end)

          if created_user_id != user_id do
            Task.start(fn ->
              Slack.API.post_message(%{
                token: access_token,
                channel: user_id,
                text: "<@#{created_user_id}> has delegated a new todo to you.",
                blocks: Renderer.render_todo(todo)
              })
            end)
          end

          # Respond with created todo
          json(conn, %{
            "response_type" => "ephemeral",
            "blocks" => Renderer.render_todo(todo)
          })

        {:error, _} ->
          json(conn, %{
            "text" => "Something went wrong, we couldn't delegate your task!"
          })
      end
    else
      json(
        conn,
        ephemeral_response([
          section("`" <> command <> " " <> text <> "`"),
          context([markdown("Sorry, that user doesn't exist.")])
        ])
      )
    end
  end

  def slash(conn, %{
        "text" => text,
        "command" => command
      }) do
    json(
      conn,
      ephemeral_response([
        section("""
          *`#{command} #{text}`*
          Sorry, I don't understand this command. Here are some commands you can try.
        """),
        Renderer.render_commands()
      ])
    )
  end
end
