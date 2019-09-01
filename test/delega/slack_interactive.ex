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
end
