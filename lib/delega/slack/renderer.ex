defmodule Delega.Slack.Renderer do
  @moduledoc """
  Library for rendering Delega business logic into Slack's message Block Kit format.
  """
  import Slack.Messaging

  alias Delega.Slack.{Action}

  defp render_channels(channels) when length(channels) > 0 do
    "\n_" <>
      (channels
       |> Enum.map(&Map.get(&1, :channel_id))
       |> Enum.map(&escape_channel/1)
       |> Enum.join(" ")) <>
      "_"
  end

  defp render_channels(channels) when length(channels) == 0 do
    ""
  end

  def escape_channel(channel_id) do
    "<#" <> channel_id <> ">"
  end

  defp render_assigned_text(created_user, assignments, created_at) do
    created_tf = dt_to_timeframe(created_at)

    assignment_chain_str =
      ([created_user.display_name] ++
         Enum.map(assignments, & &1.assigned_to_user.display_name))
      |> Enum.join(" → ")

    assignment_chain_str <> "  ·  " <> created_tf
  end

  def render_todo(
        %{
          status: "COMPLETE",
          todo: todo,
          created_at: created_at,
          created_user: created_user,
          assignments: assignments,
          completed_user: completed_user,
          completed_at: completed_at,
          channels: channels
        } = _todo,
        _action_callback = nil
      ) do
    completed_tf = dt_to_timeframe(completed_at)

    channels_str = render_channels(channels)
    assigned_str = render_assigned_text(created_user, assignments, created_at)

    text =
      ":white_check_mark: *#{todo}*\n" <>
        "_Completed by #{completed_user.display_name} #{completed_tf}  ·  #{assigned_str}_" <>
        "#{channels_str}"

    [section(text)]
  end

  def render_todo(
        %{
          status: "REJECTED",
          todo: todo,
          created_at: created_at,
          created_user: created_user,
          assignments: assignments,
          rejected_user: rejected_user,
          rejected_at: rejected_at,
          channels: channels
        } = _todo,
        _action_callback = nil
      ) do
    rejected_tf = dt_to_timeframe(rejected_at)

    channels_str = render_channels(channels)
    assigned_str = render_assigned_text(created_user, assignments, created_at)

    text =
      ":no_entry_sign: *#{todo}*\n" <>
        "_Rejected by #{rejected_user.display_name} #{rejected_tf}  ·  #{assigned_str}_" <>
        "#{channels_str}"

    [section(text)]
  end

  def render_todo(
        %{
          status: "NEW",
          todo: todo,
          todo_id: todo_id,
          created_at: created_at,
          created_user: created_user,
          assignments: assignments,
          channels: channels
        } = _todo,
        action_callback
      ) do
    channels_str = render_channels(channels)
    assigned_str = render_assigned_text(created_user, assignments, created_at)

    action_complete =
      %Action{
        todo_id: todo_id,
        action: :complete,
        callback: action_callback
      }
      |> Action.encode64()

    action_reject =
      %Action{
        todo_id: todo_id,
        action: :reject,
        callback: action_callback
      }
      |> Action.encode64()

    action_assign =
      %Action{
        todo_id: todo_id,
        action: :assign,
        callback: action_callback
      }
      |> Action.encode64()

    text =
      "*#{todo}*\n" <>
        "_#{assigned_str}_" <>
        "#{channels_str}"

    [
      section(
        text,
        overflow([
          option(":white_check_mark: Done", action_complete),
          option(":arrow_right: Assign", action_assign),
          option(":no_entry_sign: Reject", action_reject)
        ])
      )
    ]
  end

  def render_todo(%{status: "COMPLETE"} = todo) do
    render_todo(todo, nil)
  end

  def render_todo(%{status: "REJECTED"} = todo) do
    render_todo(todo, nil)
  end

  def render_todo(%{status: "NEW"} = todo) do
    render_todo(todo, nil)
  end

  def render_welcome_msg() do
    [
      section(
        ":wave: Welcome to Delega! Easily track and delegate tasks without leaving Slack. Type */dg help* or */delega help* for more information."
      )
    ]
  end

  def render_commands do
    section_with_fields([
      markdown("*Delegate a task*\n`/dg @Username Your task description`\n"),
      markdown("*List your todos*\n`/dg todo`\n"),
      markdown("*List tasks you delegated*\n`/dg list`\n"),
      markdown("*Help*\n`/dg help`\n")
    ])
  end

  @doc """
  Render the static Delega help guide.
  """
  def render_help do
    [
      section("""
      :white_check_mark: *Delega Guide*
      _Delega allows you to delegate tasks to your teammates and to yourself and track what tasks are outstanding. Delega will notify you when tasks you've delegated are completed._

      *Commands start with `/delega` or `/dg`*
      """),
      render_commands(),
      section("""
      Once you've completed a task, click the ... menu in Slack and click Done. We'll automatically notify the task owner.

      Delega commands can be run in any channel - the information is only visible to you. Delega does not post to the channel.
      """)
    ]
  end

  def render_todos(todos, action_callback) do
    todos
    |> Enum.map(&render_todo(&1, action_callback))
    |> List.flatten()
  end

  @doc """
  Render the user's todo list.
  """
  def render_todo_list(todos, _action_callback) when length(todos) == 0 do
    [section(":white_check_mark: *You have no todos!*")]
  end

  def render_todo_list(todos, action_callback) when length(todos) > 0 do
    [section(":ballot_box_with_check: *Delegated to you*")] ++
      render_todos(todos, action_callback)
  end

  def render_todo_list(todos, channel_id, _action_callback) when length(todos) == 0 do
    [section(":white_check_mark: *You have no #{escape_channel(channel_id)} todos!*")]
  end

  def render_todo_list(todos, channel_id, action_callback) when length(todos) > 0 do
    [section(":ballot_box_with_check: *Delegated to you for #{escape_channel(channel_id)}*")] ++
      render_todos(todos, action_callback)
  end

  def render_channel_todos(todos, channel_id, action_callback) when length(todos) > 0 do
    [section(":ballot_box_with_check: *#{escape_channel(channel_id)} todos*")] ++
      render_todos(todos, action_callback)
  end

  def render_channel_todos(todos, channel_id, _action_callback) when length(todos) == 0 do
    [section(":white_check_mark: *#{escape_channel(channel_id)} has no todos!*")]
  end

  def render_todo_reminder(todos, _action_callback) when length(todos) == 0 do
    nil
  end

  def render_todo_reminder(todos, action_callback) when length(todos) > 0 do
    [section(":ballot_box_with_check: *Here are today's todos:*")] ++
      render_todos(todos, action_callback)
  end

  @doc """
  Render a list of todos delegated by the user, organized by the user they are assigned to.
  """
  def render_delegation_list(todos, action_callback) when length(todos) > 0 do
    todos
    |> Enum.group_by(&Map.get(&1, :assigned_user))
    |> Enum.map(fn {user, todo_list} ->
      [section(":ballot_box_with_check: *Delegated to #{user.display_name}*")] ++
        List.flatten(
          Enum.map(
            todo_list,
            &render_todo(&1, action_callback)
          )
        )
    end)
    |> List.flatten()
  end

  def render_delegation_list(todos, _action_callback) when length(todos) == 0 do
    [section(":white_check_mark: *You have no outstanding delegations!*")]
  end

  @doc """
  Convert a raw `user_id` to be escaped for Slack.

  ## Examples

      iex> Delega.Slack.Renderer.escape_user_id("V1234567")
      "<@V1234567>"
  """
  def escape_user_id(user_id) do
    "<@" <> user_id <> ">"
  end

  @doc """
  Convert a raw `user_id` to be escaped for Slack. If `context_user_id` is the same as `user_id` we use friendly formatting instead.

  ## Examples

      iex> Delega.Slack.Renderer.escape_user_id("V1234567", "V1234567")
      "you"

      iex> Delega.Slack.Renderer.escape_user_id("V1234567", "G8943876")
      "<@V1234567>"
  """
  def escape_user_id(user_id, context_user_id) do
    case user_id == context_user_id do
      true -> "you"
      false -> escape_user_id(user_id)
    end
  end

  @doc """
  Converts the difference between the current time and `datetime` and returns it as a human readable timeframe.
  """
  def dt_to_timeframe(datetime) do
    DateTime.diff(DateTime.utc_now(), datetime)
    |> seconds_to_timeframe()
  end

  @doc """
  Converts seconds elapsed into a human-redable time frame.

  Returns `string`.

  ## Examples

      iex> Delega.Slack.Renderer.seconds_to_timeframe(25250)
      "7 hours ago"

      iex> Delega.Slack.Renderer.seconds_to_timeframe(60 * 20)
      "20 minutes ago"

      iex> Delega.Slack.Renderer.seconds_to_timeframe(60 * 5)
      "just now"

      iex> Delega.Slack.Renderer.seconds_to_timeframe(60 * 60 * 24)
      "1 day ago"

      iex> Delega.Slack.Renderer.seconds_to_timeframe(60 * 60 * 24 * 3)
      "3 days ago"
  """
  def seconds_to_timeframe(seconds) do
    days = (seconds / (60 * 60 * 24)) |> trunc()
    hours = (seconds / (60 * 60)) |> trunc()
    minutes = (seconds / 60) |> trunc()

    case {days, hours, minutes} do
      {1, _, _} -> "1 day ago"
      {d, _, _} when d > 0 -> Integer.to_string(d) <> " days ago"
      {_, 1, _} -> "1 hour ago"
      {_, h, _} when h > 0 -> Integer.to_string(h) <> " hours ago"
      {_, _, m} when m >= 10 -> Integer.to_string(m) <> " minutes ago"
      {_, _, _} -> "just now"
    end
  end
end
