defmodule DelegaWeb.SlashController do
  use DelegaWeb, :controller

  alias Delega.{Repo, Team, Todo, UserCache, User}
  alias Delega.Slack.{Renderer, Interactive}

  import Slack.Messaging

  def parse_user_token(user_token) do
    user_token
    |> String.trim()
    |> String.trim_leading("<@")
    |> String.trim_trailing(">")
    |> String.split("|")
    |> hd
  end

  def get_action_value(action) do
    case action do
      %{"type" => "overflow"} -> Map.get(action, "selected_option") |> Map.get("value")
      %{"type" => "button"} -> Map.get(action, "value")
    end
  end

  def interactivity(conn, params) do
    payload = Jason.decode!(Map.get(params, "payload"))

    user_id = payload |> Map.get("user") |> Map.get("id")
    team_id = payload |> Map.get("team") |> Map.get("id")
    response_url = payload |> Map.get("response_url")

    action_token =
      payload
      |> Map.get("actions")
      |> hd
      |> get_action_value()

    Interactive.dispatch_action(action_token, user_id, team_id, response_url)

    conn |> send_resp(200, "")
  end

  def slash(conn, %{
        "text" => "todo",
        "user_id" => user_id
      }) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Renderer.render_todo_list(user_id)
    })
  end

  def slash(conn, %{"text" => "help"}) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Renderer.render_help()
    })
  end

  def slash(conn, %{"text" => "list", "user_id" => user_id}) do
    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => Renderer.render_delegation_list(user_id)
    })
  end

  def slash(conn, %{
        "text" => "me " <> text,
        "command" => command,
        "team_id" => team_id,
        "user_id" => created_user_id
      }) do
    slash(conn, %{
      "text" => Renderer.user_id_to_str(created_user_id) <> " " <> text,
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
          if created_user_id != user_id do
            Task.start(fn ->
              Slack.API.post_message(%{
                token: access_token,
                channel: user_id,
                text: "<@#{created_user_id}> has delegated a new todo to you.",
                blocks: Renderer.render_todo(todo, :delegated_by, created_user_id, :solo)
              })
            end)
          end

          # Respond with created todo
          json(conn, %{
            "response_type" => "ephemeral",
            "blocks" => Renderer.render_todo(todo, :delegated_to, created_user_id, :solo)
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
