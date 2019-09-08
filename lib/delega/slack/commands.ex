defmodule Delega.Slack.Commands do
  alias Delega.{Todo}
  alias Delega.Slack.{ActionCallback, Renderer}

  def list_channel(channel_id) do
    callback = %ActionCallback{
      function: :list_channel,
      args: [channel_id]
    }

    todos = Todo.get_channel_todos(channel_id)

    Renderer.render_channel_todos(todos, channel_id, callback)
  end

  def list_todo_channel(user_id, channel_id) do
    callback = %ActionCallback{
      function: :list_todo_channel,
      args: [user_id, channel_id]
    }

    todos = Todo.get_assigned_todos(user_id, channel_id)

    Renderer.render_todo_list(todos, channel_id, callback)
  end

  def todo(user_id) do
    callback = %ActionCallback{
      function: :todo,
      args: [user_id]
    }

    todos = Todo.get_assigned_todos(user_id)

    Renderer.render_todo_list(todos, callback)
  end

  def created_list(user_id) do
    callback = %ActionCallback{
      function: :created_list,
      args: [user_id]
    }

    todos = Todo.get_created_todos(user_id)

    Renderer.render_delegation_list(todos, callback)
  end

  def todo_reminder(user_id) do
    callback = %ActionCallback{
      function: :todo_reminder,
      args: [user_id]
    }

    todos = Todo.get_assigned_todos(user_id)

    Renderer.render_todo_reminder(todos, callback)
  end
end
