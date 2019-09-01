defmodule Delega.SlackInteractiveTest do
  use Delega.DataCase, async: true
  doctest Delega.Slack.Interactive

  import Delega.Slack.Interactive

  alias Delega.{Repo, Team, Todo}

  @base_url Application.get_env(:delega, :slack_base_url)

  test "parse_action" do
    assert parse_action("todo_list:complete:35") == %{
             context: "todo_list",
             action: "complete",
             todo_id: 35
           }
  end

  test "send_complete_msg" do
    send_complete_msg(
      "Kyle",
      %{completed_user_id: "Gely", todo: "Test Todo"},
      "an access token secret"
    )
  end

  def setup do
    team = %Team{team_id: "Delega", access_token: "a big secret"} |> Repo.insert!(returning: true)

    todo =
      %Todo{
        team_id: "Delega",
        created_user_id: "Kyle",
        assigned_user_id: "Gely",
        todo: "Do some things"
      }
      |> Repo.insert!(returning: true)

    {team, todo}
  end

  test "dispatch_action - complete" do
    {_team, todo} = setup()

    dispatch_action(
      "todo_list:complete:#{todo.todo_id}",
      "Kyle",
      "Delega",
      @base_url <> "response_url"
    )

    todo = Repo.get!(Todo, todo.todo_id)

    assert todo.is_complete == true
    assert todo.completed_user_id == "Kyle"
  end

  test "dispatch_action - reject" do
    {_team, todo} = setup()

    dispatch_action(
      "todo_list:reject:#{todo.todo_id}",
      "Kyle",
      "Delega",
      @base_url <> "response_url"
    )

    assert Repo.get(Todo, todo.todo_id) == nil
  end
end
