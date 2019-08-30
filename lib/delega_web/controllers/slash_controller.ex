defmodule DelegaWeb.SlashController do
  use DelegaWeb, :controller

  alias Delega.Repo
  alias Delega.Team
  alias Delega.Todo
  alias Delega.UserCache

  import Slack.Messaging

  import Ecto.Query, only: [from: 2]

  def parse_user_token(user_token) do
    [user_id | _] =
      user_token
      |> String.trim()
      |> String.trim_leading("<@")
      |> String.trim_trailing(">")
      |> String.split("|")

    user_id
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

    payload
    |> Map.get("actions")
    |> Enum.map(&get_action_value/1)
    |> Enum.map(&process_action(team_id, user_id, &1, response_url))

    conn |> send_resp(200, "")
  end

  def send_complete_msg(
        to_user_id,
        %{completed_user_id: completed_user_id, todo: todo},
        access_token
      ) do
    Slack.API.post_message(%{
      token: access_token,
      channel: to_user_id,
      text: "<@#{completed_user_id} completed #{todo}",
      blocks: [
        section(":white_check_mark: *#{todo}*\n _Completed by <@#{completed_user_id}>_")
      ]
    })
  end

  def send_reject_msg(
        to_user_id,
        deleted_user_id,
        %{todo: todo},
        access_token
      ) do
    Slack.API.post_message(%{
      token: access_token,
      channel: to_user_id,
      text: "<@#{deleted_user_id} rejected #{todo}",
      blocks: [
        section(":no_entry_sign: *#{todo}*\n_Rejected by <@#{deleted_user_id}>_")
      ]
    })
  end

  def process_action(team_id, completed_user_id, "complete:" <> todo_id, response_url) do
    todo_id = todo_id |> String.to_integer()

    todo = Todo |> Repo.get!(todo_id)

    if not todo.is_complete do
      %{access_token: access_token} = Team |> Repo.get!(team_id)

      # Mark todo complete in db
      todo = Ecto.Changeset.change(todo, completed_user_id: completed_user_id, is_complete: true)
      todo = Repo.update!(todo)

      # Update users that are interested in todo that it's complete
      MapSet.new([completed_user_id, todo.created_user_id, todo.assigned_user_id])
      |> MapSet.delete(completed_user_id)
      |> Enum.map(&Task.start(fn -> send_complete_msg(&1, todo, access_token) end))

      Task.start(fn ->
        HTTPoison.post!(
          response_url,
          Jason.encode!(%{
            # "replace_original" => "false",
            "response_type" => "ephemeral",
            "text" => ":white_check_mark: *#{todo.todo}*\n _Completed by <@#{completed_user_id}>_"
          }),
          [{"Content-type", "application/json"}]
        )
      end)
    end
  end

  def process_action(team_id, deleted_user_id, "reject:" <> todo_id, response_url) do
    todo_id = todo_id |> String.to_integer()

    todo = Todo |> Repo.get!(todo_id)

    if not todo.is_complete do
      %{access_token: access_token} = Team |> Repo.get!(team_id)

      Repo.delete!(todo)

      # Update users that are interested in todo that it's been deleted
      MapSet.new([deleted_user_id, todo.created_user_id, todo.assigned_user_id])
      |> MapSet.delete(deleted_user_id)
      |> Enum.map(&Task.start(fn -> send_reject_msg(&1, deleted_user_id, todo, access_token) end))

      Task.start(fn ->
        HTTPoison.post!(
          response_url,
          Jason.encode!(%{
            # "replace_original" => "false",
            "response_type" => "ephemeral",
            "text" => ":no_entry_sign: *#{todo.todo}*\n_Rejected by <@#{deleted_user_id}>_"
          }),
          [{"Content-type", "application/json"}]
        )
      end)
    end
  end

  def seconds_to_string(seconds) do
    days = (seconds / (60 * 60 * 24)) |> trunc()
    hours = (seconds / (60 * 60)) |> trunc()
    minutes = (seconds / 60) |> trunc()

    case {days, hours, minutes} do
      {1, _, _} -> "1 day ago"
      {d, _, _} when d > 0 -> Integer.to_string(d) <> " days ago"
      {_, 1, _} -> "1 hour ago"
      {_, h, _} when h > 0 -> Integer.to_string(h) <> " hours ago"
      {_, _, m} when m >= 10 -> Integer.to_string(m) <> " minutes ago"
      {_, _, _} -> "just now"
    end
  end

  def todo_block(
        %{
          created_user_id: created_user_id,
          todo: todo,
          todo_id: todo_id,
          created_at: created_at,
          assigned_user_id: assigned_user_id
        },
        type
      ) do
    timeframe =
      DateTime.diff(DateTime.utc_now(), created_at)
      |> seconds_to_string()

    user_phrasing =
      case type do
        :delegated_by -> "by <@#{created_user_id}>"
        :delegated_to -> "to <@#{assigned_user_id}>"
        :none -> ""
      end

    [
      section(
        "*#{todo}*\n_Delegated #{timeframe} #{user_phrasing}_",
        overflow([
          option(":white_check_mark: Done", "complete:#{todo_id}"),
          option(":no_entry_sign: Reject", "reject:#{todo_id}")
        ])
      )
    ]
  end

  def slash(conn, %{
        "text" => "todo",
        "user_id" => user_id
      }) do
    todos =
      Repo.all(
        from t in Todo,
          where: t.assigned_user_id == ^user_id and t.is_complete == false
      )

    blocks =
      case length(todos) do
        0 ->
          [section("*You have no todos!*")]

        _ ->
          [section(":ballot_box_with_check: *Delegated to <@#{user_id}>*")] ++
            List.flatten(Enum.map(todos, &todo_block(&1, :delegated_by)))
      end

    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => blocks
    })
  end

  def slash(conn, %{
        "text" => "list",
        "user_id" => user_id
      }) do
    todos =
      Repo.all(
        from t in Todo,
          where:
            t.is_complete == false and
              t.created_user_id == ^user_id and
              t.assigned_user_id != ^user_id
      )

    blocks =
      case length(todos) do
        0 ->
          [section("*You have no outstanding delegations!*")]

        _ ->
          todos_by_user_id = todos |> Enum.group_by(&Map.get(&1, :assigned_user_id))

          # sections =
          todos_by_user_id
          |> Enum.map(fn {user_id, todo_list} ->
            [section(":ballot_box_with_check: *Delegated to <@#{user_id}>*")] ++
              List.flatten(Enum.map(todo_list, &todo_block(&1, :none)))
          end)
          |> List.flatten()
      end

    json(conn, %{
      "response_type" => "ephemeral",
      "blocks" => blocks
    })
  end

  def slash(conn, %{
        "text" => text,
        "command" => command,
        "team_id" => team_id,
        "user_id" => created_user_id
      }) do
    text = String.trim(text)
    [user_token | _] = String.split(text)

    user_id = parse_user_token(user_token)

    todo_msg =
      text
      |> String.trim_leading(user_token <> " ")

    %{access_token: access_token} = team = Repo.get!(Team, team_id)

    if UserCache.valid_user?(team, user_id) do
      todo = %Todo{
        team_id: team_id,
        assigned_user_id: user_id,
        created_user_id: created_user_id,
        todo: todo_msg
      }

      case Repo.insert(todo) do
        {:ok, todo} ->
          todo_id_str = Integer.to_string(todo.todo_id)

          if created_user_id != user_id do
            Task.start(fn ->
              Slack.API.post_message(%{
                token: access_token,
                channel: user_id,
                text: "<@#{created_user_id}> has delegated a new todo to you.",
                blocks: [
                  section(
                    "*#{todo_msg}*\n_Delegated by <@#{created_user_id}>_",
                    overflow([
                      option(":white_check_mark: Done", "complete:#{todo_id_str}"),
                      option(":no_entry_sign: Reject", "reject:#{todo_id_str}")
                    ])
                  )
                ]
              })
            end)
          end

          # Respond with created todo
          json(conn, %{
            "response_type" => "ephemeral",
            "blocks" => [
              section(
                "*#{todo_msg}*\n_Delegated to <@#{user_id}>_",
                overflow([
                  option(":white_check_mark: Done", "complete:#{todo_id_str}"),
                  option(":no_entry_sign: Reject", "reject:#{todo_id_str}")
                ])
              )
            ]
          })

        {:error, _} ->
          json(conn, %{
            "text" => "Something went wrong!"
          })
      end
    else
      json(
        conn,
        ephemeral_response([
          section("*" <> command <> " " <> text <> "*"),
          context([markdown("Sorry, that user doesn't exist.")])
        ])
      )
    end
  end
end
