defmodule Delega.Reminders do
  use Quantum.Scheduler,
    otp_app: :delega

  alias Delega.{Repo, Team, Todo, UserCache}

  import Ecto.Query, only: [from: 2]

  def reminder?(now, reminder_time, tz_offset, tolerance) do
    now_tz = Time.add(now, tz_offset)

    diff = Time.diff(now_tz, reminder_time)

    diff < tolerance and diff >= 0
  end

  def send_reminders(reminder_hour, reminder_minute) do
    now = Time.utc_now()
    {:ok, reminder_time} = Time.new(reminder_hour, reminder_minute, 0, 0)

    users_with_todos =
      from(team in Team,
        distinct: true,
        join: todo in Todo,
        on: todo.team_id == team.team_id,
        where: todo.status == "NEW",
        select: %{
          team_id: team.team_id,
          access_token: team.access_token,
          user_id: todo.assigned_user_id
        }
      )
      |> Repo.all()

    users_with_todos
    |> Enum.map(fn user ->
      tz_offset =
        UserCache.get(user.team_id)
        |> Map.get(user.user_id)
        |> Map.get(:tz_offset)

      if reminder?(now, reminder_time, tz_offset, 60 * 59) do
        Task.start(fn ->
          Delega.Slack.Interactive.send_todo_reminder(user.access_token, user.user_id)
        end)
      end
    end)
  end
end
