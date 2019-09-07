defmodule Delega.SlackInteractiveTest do
  use Delega.DataCase, async: true
  doctest Delega.Slack.Interactive

  import Delega.Slack.Interactive

  alias Delega.{Repo, Team, Todo, User}

  @base_url Application.get_env(:delega, :slack_base_url)

  setup do
    team = %Team{team_id: "Delega", access_token: "a big secret"} |> Repo.insert!(returning: true)

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

  test "parse_action" do
    assert parse_action("todo_list:complete:35") == %{
             context: "todo_list",
             action: "complete",
             todo_id: 35
           }
  end

  test "dispatch_action - complete", %{todo: todo} do
    dispatch_action(
      "todo_list:complete:#{todo.todo_id}",
      "Kyle",
      "Delega",
      @base_url <> "response_url"
    )

    todo = Repo.get!(Todo, todo.todo_id)

    assert todo.status == "COMPLETE"
    assert todo.completed_user_id == "Kyle"
  end

  test "dispatch_action - reject", %{todo: todo} do
    dispatch_action(
      "todo_list:reject:#{todo.todo_id}",
      "Kyle",
      "Delega",
      @base_url <> "response_url"
    )

    todo = Repo.get!(Todo, todo.todo_id)

    assert todo.status == "REJECTED"
    assert todo.rejected_user_id != nil
    assert todo.rejected_at != nil
  end
end
