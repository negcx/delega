defmodule Delega.Slack.Interactive do
  @moduledoc """
  Logic for interacting with Slack.
  """

  alias Delega.Slack.{Renderer, Commands}
  alias Delega.{Repo, Team, Todo, TodoAssignment, User}

  def send_complete_msg(
        to_user_id,
        todo = %{completed_user_id: completed_user_id, todo: todo_msg},
        access_token
      ) do
    Slack.API.post_message(%{
      token: access_token,
      channel: to_user_id,
      text: "#{Renderer.escape_user_id(completed_user_id)} completed #{todo_msg}",
      blocks: Renderer.render_todo(todo)
    })
  end

  def send_reject_msg(
        to_user_id,
        deleted_user_id,
        todo,
        access_token
      ) do
    Slack.API.post_message(%{
      token: access_token,
      channel: to_user_id,
      text: "#{Renderer.escape_user_id(deleted_user_id)} rejected #{todo.todo}",
      blocks: Renderer.render_todo(todo)
    })
  end

  def send_bulk_complete_msg(todo, access_token) do
    MapSet.new(
      [todo.completed_user_id, todo.created_user_id, todo.assigned_user_id] ++
        Enum.map(todo.assignments, & &1.assigned_to_user_id) ++
        Enum.map(todo.assignments, & &1.assigned_by_user_id)
    )
    |> MapSet.delete(todo.completed_user_id)
    |> Enum.map(&Task.start(fn -> send_complete_msg(&1, todo, access_token) end))
  end

  def send_bulk_reject_msg(todo, rejected_user_id, access_token) do
    MapSet.new(
      [todo.completed_user_id, todo.created_user_id, todo.assigned_user_id] ++
        Enum.map(todo.assignments, & &1.assigned_to_user_id) ++
        Enum.map(todo.assignments, & &1.assigned_by_user_id)
    )
    |> MapSet.delete(rejected_user_id)
    |> Enum.map(
      &Task.start(fn ->
        send_reject_msg(&1, rejected_user_id, todo, access_token)
      end)
    )
  end

  def get_action_value(action) do
    case action do
      %{"type" => "overflow"} -> Map.get(action, "selected_option") |> Map.get("value")
      %{"type" => "button"} -> Map.get(action, "value")
    end
  end

  def notify_channels(todo, access_token, text, blocks) do
    todo
    |> Ecto.assoc(:channels)
    |> Repo.all()
    |> Enum.map(&Map.get(&1, :channel_id))
    |> Enum.map(fn channel_id ->
      Task.start(fn ->
        Slack.API.post_message(%{
          token: access_token,
          text: text,
          channel: channel_id,
          blocks: blocks
        })
      end)
    end)
  end

  def send_welcome_msg(user_id, access_token) do
    Slack.API.post_message(%{
      token: access_token,
      channel: user_id,
      blocks: Renderer.render_welcome_msg(),
      text: "Welcome to Delega!"
    })
  end

  def do_action(:complete, todo, completed_user_id, access_token, _trigger_id) do
    if todo.status != "COMPLETE" do
      todo = todo |> Todo.complete!(completed_user_id)

      todo = Todo.get_with_assoc(todo.todo_id)

      send_bulk_complete_msg(todo, access_token)

      notify_channels(
        todo,
        access_token,
        "#{Renderer.escape_user_id(completed_user_id)} completed #{todo.todo}",
        Renderer.render_todo(todo)
      )

      Renderer.render_todo(todo)
    else
      Renderer.render_todo(todo)
    end
  end

  def do_action(:reject, todo, rejected_user_id, access_token, _trigger_id) do
    if todo.status != "COMPLETE" do
      todo =
        todo
        |> Todo.reject!(rejected_user_id)

      todo = Todo.get_with_assoc(todo.todo_id)

      send_bulk_reject_msg(todo, rejected_user_id, access_token)

      notify_channels(
        todo,
        access_token,
        "#{Renderer.escape_user_id(rejected_user_id)} rejected #{todo.todo}",
        Renderer.render_todo(todo)
      )

      Renderer.render_todo(todo)
    else
      Renderer.render_todo(todo)
    end
  end

  def do_action(:assign, todo, _user_id, access_token, trigger_id) do
    Task.start(fn ->
      state =
        %{"todo_id" => todo.todo_id}
        |> Jason.encode!()
        |> Base.encode64()

      Slack.API.dialog_open(access_token, trigger_id, %{
        "callback_id" => "assign",
        "title" => "Assign a Todo",
        "submit_label" => "Assign",
        "state" => state,
        "elements" => [
          %{
            "type" => "select",
            "label" => "Assign to...",
            "name" => "assign_to",
            "data_source" => "users"
          }
        ]
      })
    end)

    []
  end

  def send_todo_reminder(access_token, user_id) do
    blocks = Commands.todo_reminder(user_id)

    if blocks != nil do
      Slack.API.post_message(%{
        token: access_token,
        channel: user_id,
        blocks: blocks,
        text: "Here are your todos for today"
      })
    end
  end

  def process_interaction(
        %{
          "type" => "block_actions",
          "response_url" => response_url,
          "trigger_id" => trigger_id
        } = payload
      ) do
    user_id = payload |> Map.get("user") |> Map.get("id")
    team_id = payload |> Map.get("team") |> Map.get("id")

    action =
      payload
      |> Map.get("actions")
      |> hd
      |> get_action_value()
      |> Delega.Slack.Action.decode64()

    dispatch_action(action, user_id, team_id, response_url, trigger_id)
  end

  def process_interaction(
        %{
          "type" => "dialog_submission",
          "callback_id" => "assign",
          "state" => state,
          "user" => %{"id" => user_id},
          "team" => %{"id" => team_id},
          "submission" => %{"assign_to" => assign_to_user_id},
          "response_url" => response_url
        } = payload
      ) do
    %{"todo_id" => todo_id} =
      state
      |> Base.decode64!()
      |> Jason.decode!()

    %{access_token: access_token} = Team |> Repo.get!(team_id)
    todo = Todo.get_with_assoc(todo_id)

    case todo do
      %{status: "COMPLETE"} ->
        Task.start(fn ->
          Slack.API.simple_response(response_url, "That todo is already complete!")
        end)

      %{assigned_user_id: ^assign_to_user_id} ->
        Task.start(fn ->
          Slack.API.simple_response(response_url, "That todo is already assigned to that user.")
        end)

      todo ->
        Todo.reassign!(todo, user_id, assign_to_user_id)
        todo = Todo.get_with_assoc(todo_id)

        assigned_by = Repo.get!(User, user_id)
        assigned_to = Repo.get!(User, assign_to_user_id)

        blocks =
          Renderer.render_todo(todo) ++
            [
              Slack.Messaging.section(
                ":arrow_right: _#{assigned_by.display_name} assigned to #{
                  assigned_to.display_name
                }_"
              )
            ]

        # Send response to creator
        Task.start(fn ->
          HTTPoison.post!(
            response_url,
            Jason.encode!(%{
              "response_type" => "ephemeral",
              "blocks" => blocks
            }),
            [{"Content-type", "application/json"}]
          )
        end)

        # Post messages to followers
        MapSet.new(
          [todo.created_user_id, todo.assigned_user_id] ++
            Enum.map(todo.assignments, & &1.assigned_to_user_id) ++
            Enum.map(todo.assignments, & &1.assigned_by_user_id)
        )
        |> MapSet.delete(user_id)
        |> Enum.map(
          &Task.start(fn ->
            Slack.API.post_message(%{
              token: access_token,
              channel: &1,
              text:
                "#{Renderer.escape_user_id(user_id)} re-assigned #{todo.todo} to #{
                  assign_to_user_id
                }",
              blocks: Renderer.render_todo(todo)
            })
          end)
        )
    end
  end

  def dispatch_action(
        %{action: action, callback: callback, todo_id: todo_id},
        action_user_id,
        team_id,
        response_url,
        trigger_id
      ) do
    %{access_token: access_token} = Team |> Repo.get!(team_id)
    todo = Todo.get_with_assoc(todo_id)

    action_blocks = do_action(action, todo, action_user_id, access_token, trigger_id)

    context_blocks = Delega.Slack.ActionCallback.execute(callback)

    blocks = (context_blocks ++ action_blocks) |> List.flatten()

    # Send response to Slack
    Task.start(fn ->
      HTTPoison.post!(
        response_url,
        Jason.encode!(%{
          "response_type" => "ephemeral",
          "blocks" => blocks
        }),
        [{"Content-type", "application/json"}]
      )
    end)
  end
end
