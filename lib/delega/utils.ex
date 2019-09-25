defmodule Delega.Utils do
  alias Delega.{Repo, User, Team}
  alias Delega.Slack.Interactive

  import Ecto.Query, only: [from: 2]

  def update_user_channels() do
    from(user in User,
      join: team in Team,
      on: team.team_id == user.team_id,
      where: not is_nil(team.bot_access_token) and is_nil(user.channel_id),
      select: %{user_id: user.user_id, bot_access_token: team.bot_access_token}
    )
    |> Repo.all()
    |> Enum.map(fn u ->
      Task.start(fn ->
        channel_id = Interactive.get_user_channel(u.bot_access_token, u.user_id)

        Ecto.Changeset.change(%User{user_id: u.user_id}, channel_id: channel_id)
        |> Repo.update!()
      end)
    end)
  end
end
