defmodule Delega.SlackInteractiveTest do
  use Delega.DataCase, async: true
  doctest Delega.Slack.Interactive

  import Delega.Slack.Interactive

  alias Delega.{Repo, Team, Todo, User}
  alias Delega.Slack.Action

  @base_url Application.get_env(:delega, :slack_base_url)

  setup do
    team =
      %Team{team_id: "Delega", access_token: "a big secret", bot_access_token: "blah"}
      |> Repo.insert!(returning: true)

    %User{
      user_id: "Kyle",
      team_id: "Delega",
      tz_offset: -25200,
      display_name: "kylesito",
      is_deleted: false
    }
    |> Repo.insert!(returning: true)

    %User{
      user_id: "Gely",
      team_id: "Delega",
      tz_offset: -25200,
      display_name: "gelita",
      is_deleted: false
    }
    |> Repo.insert!(returning: true)

    todo =
      %Todo{
        team_id: "Delega",
        created_user_id: "Kyle",
        assigned_user_id: "Gely",
        todo: "Do some things"
      }
      |> Repo.insert!(returning: true)

    [team: team, todo: todo]
  end

  test "dispatch_action - complete", %{todo: todo} do
    action = %Action{
      action: :complete,
      todo_id: todo.todo_id,
      callback: nil
    }

    dispatch_action(
      action,
      "Kyle",
      "Delega",
      @base_url <> "response_url",
      "trigger"
    )

    todo = Repo.get!(Todo, todo.todo_id)

    assert todo.status == "COMPLETE"
    assert todo.completed_user_id == "Kyle"
  end

  test "dispatch_action - reject", %{todo: todo} do
    action = %Action{
      action: :reject,
      todo_id: todo.todo_id,
      callback: nil
    }

    dispatch_action(
      action,
      "Kyle",
      "Delega",
      @base_url <> "response_url",
      "trigger"
    )

    todo = Repo.get!(Todo, todo.todo_id)

    assert todo.status == "REJECTED"
    assert todo.rejected_user_id != nil
    assert todo.rejected_at != nil
  end
end
