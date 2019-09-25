defmodule Delega.Slack.Interactive do
  @moduledoc """
  Logic for interacting with Slack.
  """

  alias Delega.Slack.{Renderer, Commands, Interactive}
  alias Delega.{Repo, Team, Todo, User}

  def send_complete_msg(
        %User{} = user,
        todo = %{completed_user_id: completed_user_id, todo: todo_msg},
        %Team{} = team
      ) do
    send_im(%{
      team: team,
      user: user,
      text: "#{Renderer.escape_user_id(completed_user_id)} completed #{todo_msg}",
      blocks: Renderer.render_todo(todo)
    })
  end

  def get_user_channel(bot_access_token, user_id) do
    Slack.API.im_open(bot_access_token, user_id)
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("channel")
    |> Map.get("id")
  end

  def send_im(%{
        team: %{bot_access_token: bot_access_token, access_token: access_token},
        user: %{user_id: user_id, channel_id: channel},
        text: text,
        blocks: blocks
      }) do
    case bot_access_token do
      nil ->
        Slack.API.post_message(%{
          token: access_token,
          channel: user_id,
          text: text,
          blocks: blocks
        })

      bot_access_token ->
        channel =
          case channel do
            nil ->
              get_user_channel(bot_access_token, user_id)

            channel ->
              channel
          end

        Slack.API.post_message(%{
          token: bot_access_token,
          channel: channel,
          text: text,
          blocks: blocks
        })
    end
  end

  def send_reject_msg(
        %User{} = user,
        deleted_user_id,
        todo,
        %Team{} = team
      ) do
    send_im(%{
      team: team,
      user: user,
      text: "#{Renderer.escape_user_id(deleted_user_id)} rejected #{todo.todo}",
      blocks: Renderer.render_todo(todo)
    })
  end

  def send_bulk_complete_msg(todo, %Team{} = team) do
    MapSet.new(
      [todo.completed_user, todo.created_user, todo.assigned_user] ++
        Enum.map(todo.assignments, & &1.assigned_to_user) ++
        Enum.map(todo.assignments, & &1.assigned_by_user)
    )
    |> MapSet.delete(todo.completed_user)
    |> Enum.map(&Task.start(fn -> send_complete_msg(&1, todo, team) end))
  end

  def send_bulk_reject_msg(
        %Todo{} = todo,
        rejected_user_id,
        %{access_token: _access_token, bot_access_token: _bot_access_token} = team
      ) do
    MapSet.new(
      [todo.rejected_user, todo.created_user, todo.assigned_user] ++
        Enum.map(todo.assignments, & &1.assigned_to_user) ++
        Enum.map(todo.assignments, & &1.assigned_by_user)
    )
    |> MapSet.delete(todo.rejected_user)
    |> Enum.map(
      &Task.start(fn ->
        send_reject_msg(&1, rejected_user_id, todo, team)
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

  def send_welcome_msg(%User{} = user, %Team{} = team) do
    send_im(%{
      user: user,
      team: team,
      blocks: Renderer.render_welcome_msg(),
      text: "Welcome to Delega!"
    })
  end

  def do_action(
        :complete,
        todo,
        completed_user_id,
        team,
        _trigger_id
      ) do
    if todo.status != "COMPLETE" do
      todo = todo |> Todo.complete!(completed_user_id)

      todo = Todo.get_with_assoc(todo.todo_id)

      send_bulk_complete_msg(todo, team)

      notify_channels(
        todo,
        team.access_token,
        "#{Renderer.escape_user_id(completed_user_id)} completed #{todo.todo}",
        Renderer.render_todo(todo)
      )

      Renderer.render_todo(todo)
    else
      Renderer.render_todo(todo)
    end
  end

  def do_action(
        :reject,
        todo,
        rejected_user_id,
        %{access_token: access_token, bot_access_token: _bot_access_token} = team,
        _trigger_id
      ) do
    if todo.status != "COMPLETE" do
      todo =
        todo
        |> Todo.reject!(rejected_user_id)

      todo = Todo.get_with_assoc(todo.todo_id)

      send_bulk_reject_msg(todo, todo.rejected_user_id, team)

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

  def do_action(
        :assign,
        todo,
        _user_id,
        %{access_token: access_token},
        trigger_id
      ) do
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

  def send_todo_reminder(%Team{} = team, %User{} = user) do
    blocks = Commands.todo_reminder(user.user_id)

    if blocks != nil do
      Interactive.send_im(%{
        team: team,
        user: user,
        text: "Here are your todos for today",
        blocks: blocks
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
        } = _payload
      ) do
    %{"todo_id" => todo_id} =
      state
      |> Base.decode64!()
      |> Jason.decode!()

    team = Team |> Repo.get!(team_id)
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
          [todo.created_user, todo.assigned_user] ++
            Enum.map(todo.assignments, & &1.assigned_to_user) ++
            Enum.map(todo.assignments, & &1.assigned_by_user)
        )
        |> MapSet.delete(assigned_by)
        |> Enum.map(
          &Task.start(fn ->
            send_im(%{
              team: team,
              user: &1,
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
    team = Team |> Repo.get!(team_id)
    todo = Todo.get_with_assoc(todo_id)

    action_blocks = do_action(action, todo, action_user_id, team, trigger_id)

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
