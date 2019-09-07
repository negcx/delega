defmodule Delega.Slack.Renderer do
  @moduledoc """
  Library for rendering Delega business logic into Slack's message Block Kit format.
  """
  import Slack.Messaging

  alias Delega.Todo

  @doc """
  Render a single todo with different phrasing depending on whether the todo is complete and depending on the options passed to `phrasing`.

  `phrasing` can be `:delegated_by`, `:deegated_to`, or `:none`
  """
  def render_todo(
        %{
          created_user_id: created_user_id,
          todo: todo,
          todo_id: todo_id,
          created_at: created_at,
          assigned_user_id: assigned_user_id,
          status: status,
          completed_user_id: completed_user_id,
          completed_at: completed_at
        } = _todo,
        phrasing,
        context_user_id,
        source
      ) do
    timeframe = dt_to_timeframe(created_at)

    user_phrasing =
      case phrasing do
        :delegated_by ->
          created_user_str = user_id_to_str(created_user_id, context_user_id)
          "*#{todo}*\n_Delegated #{timeframe} by #{created_user_str}_"

        :delegated_to ->
          assigned_user_str = user_id_to_str(assigned_user_id, context_user_id)
          "*#{todo}*\n_Delegated #{timeframe} to #{assigned_user_str}_"

        :delegated_timeframe ->
          "*#{todo}*\n_Delegated #{timeframe}_"

        :public ->
          created_user_str = user_id_to_str(created_user_id, context_user_id)
          assigned_user_str = user_id_to_str(assigned_user_id, context_user_id)
          "*#{todo}*\n_Delegated by #{created_user_str} to #{assigned_user_str} #{timeframe}_"
      end

    source_str =
      case source do
        :todo_list -> "todo_list"
        :delegation_list -> "delegation_list"
        _ -> "solo"
      end

    case status do
      "NEW" ->
        [
          section(
            user_phrasing,
            overflow([
              option(":white_check_mark: Done", "#{source_str}:complete:#{todo_id}"),
              option(":no_entry_sign: Reject", "#{source_str}:reject:#{todo_id}")
            ])
          )
        ]

      "COMPLETE" ->
        completed_user_str = user_id_to_str(completed_user_id, context_user_id)
        completed_timeframe = dt_to_timeframe(completed_at)

        [
          section(
            ":white_check_Mark: *#{todo}*\n_Delegated #{timeframe} #{user_phrasing}, completed #{
              completed_timeframe
            } by #{completed_user_str}_"
          )
        ]
    end
  end

  def render_todo_complete_msg(
        %{todo: todo, completed_user_id: completed_user_id},
        context_user_id
      ) do
    completed_user_str = user_id_to_str(completed_user_id, context_user_id)

    [section(":white_check_mark: *#{todo}*\n _Completed by #{completed_user_str}_")]
  end

  def render_welcome_msg() do
    # TODO
    [
      section(
        ":wave: Welcome to Delega! Easily track and delegate tasks. Type */dg help* or */delega help* for more information."
      )
    ]
  end

  def render_todo_reject_msg(%{todo: todo}, deleted_user_id, context_user_id) do
    [
      section(
        ":no_entry_sign: *#{todo}*\n_Rejected by #{
          user_id_to_str(deleted_user_id, context_user_id)
        }_"
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

  @doc """
  Render the user's todo list.
  """
  def render_todo_list(user_id) do
    todos = Todo.get_todo_list(user_id)

    case length(todos) do
      0 ->
        [section(":white_check_mark: *You have no todos!*")]

      _ ->
        [section(":ballot_box_with_check: *Delegated to you*")] ++
          List.flatten(Enum.map(todos, &render_todo(&1, :delegated_by, user_id, :todo_list)))
    end
  end

  def render_todo_reminder(todos, user_id) do
    [section(":ballot_box_with_check: *Here are today's todos:*")] ++
      List.flatten(Enum.map(todos, &render_todo(&1, :delegated_by, user_id, :todo_list)))
  end

  @doc """
  Render a list of todos delegated by the user, organized by the user they are assigned to.
  """
  def render_delegation_list(user_id) do
    todos = Todo.get_delegation_list(user_id)

    case length(todos) do
      0 ->
        [section(":white_check_mark: *You have no outstanding delegations!*")]

      _ ->
        todos
        |> Enum.group_by(&Map.get(&1, :assigned_user_id))
        |> Enum.map(fn {user_id, todo_list} ->
          [section(":ballot_box_with_check: *Delegated to <@#{user_id}>*")] ++
            List.flatten(
              Enum.map(
                todo_list,
                &render_todo(&1, :delegated_timeframe, user_id, :delegation_list)
              )
            )
        end)
        |> List.flatten()
    end
  end

  @doc """
  Convert a raw `user_id` to be escaped for Slack.

  ## Examples

      iex> Delega.Slack.Renderer.user_id_to_str("V1234567")
      "<@V1234567>"
  """
  def user_id_to_str(user_id) do
    "<@" <> user_id <> ">"
  end

  @doc """
  Convert a raw `user_id` to be escaped for Slack. If `context_user_id` is the same as `user_id` we use friendly formatting instead.

  ## Examples

      iex> Delega.Slack.Renderer.user_id_to_str("V1234567", "V1234567")
      "you"

      iex> Delega.Slack.Renderer.user_id_to_str("V1234567", "G8943876")
      "<@V1234567>"
  """
  def user_id_to_str(user_id, context_user_id) do
    case user_id == context_user_id do
      true -> "you"
      false -> user_id_to_str(user_id)
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
