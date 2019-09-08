defmodule Delega.ActionTest do
  use ExUnit.Case, async: true

  alias Delega.Slack.{Action, ActionCallback}

  describe "Delega.ActionTest" do
    test "Action |> encode |> decode == Action" do
      action = %Action{
        action: :complete,
        todo_id: 10,
        callback: %ActionCallback{
          function: :todo,
          args: ["Kyle"]
        }
      }

      encoded_and_decoded =
        action
        |> Action.encode64()
        |> Action.decode64()

      assert action == encoded_and_decoded
    end

    test "Action (null callback) |> encode |> decode == Action" do
      action = %Action{
        action: :complete,
        todo_id: 10,
        callback: nil
      }

      encoded_and_decoded =
        action
        |> Action.encode64()
        |> Action.decode64()

      assert action == encoded_and_decoded
    end
  end
end
