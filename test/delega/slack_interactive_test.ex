defmodule Delega.SlackInteractiveTest do
  use ExUnit.Case, async: true
  doctest Delega.Slack.Interactive

  import Delega.Slack.Interactive

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
end
