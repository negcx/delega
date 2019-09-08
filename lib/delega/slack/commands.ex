defmodule Delega.Slack.Commands do
  alias Delega.{Todo}
  alias Delega.Slack.{ActionCallback, Renderer}

  def list_channel(channel_id) do
    callback =
      %ActionCallback{
        function: :list_channel,
        args: [channel_id]
      }
      |> Jason.encode!()

    todos = Todo.get_channel_todos(channel_id)

    Renderer.render_channel_todos(todos, channel_id, callback)
  end
end
