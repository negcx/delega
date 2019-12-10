defmodule Delega.UserCache do
  use GenServer

  alias Delega.{Repo, User}
  alias Delega.Slack.Interactive

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: UserCache)
  end

  def init(state) do
    :ets.new(:user_cache, [:set, :protected, :named_table])

    teams = Delega.Team |> Delega.Repo.all()

    teams
    |> Enum.map(&Task.start(fn -> Delega.UserCache.load_from_slack(&1) end))

    {:ok, state}
  end

  def put(key, data) do
    GenServer.cast(UserCache, {:put, key, data})
  end

  def get(key) do
    case :ets.lookup(:user_cache, key) do
      [] -> []
      [{_key, users}] -> users
    end
  end

  def load_from_slack(%{team_id: team_id, access_token: access_token}) do
    IO.puts("team_id: " <> team_id)

    users =
      IO.inspect(Slack.API.get_users(access_token))
      |> Map.get(:body)
      |> Jason.decode!()
      |> Map.get("members")
      |> Enum.reduce(Map.new(), fn user, map ->
        Map.put(map, Map.get(user, "id"), %{
          user_id: Map.get(user, "id"),
          tz_offset: Map.get(user, "tz_offset"),
          team_id: team_id,
          is_deleted: Map.get(user, "deleted"),
          display_name: Map.get(user, "profile") |> Map.get("display_name_normalized")
        })
      end)

    Delega.UserCache.put(team_id, users)
  end

  def safe_get(team_id) do
    GenServer.call(UserCache, {:get, team_id})
  end

  def valid_user?(%{team_id: team_id, access_token: _} = team, user_id) do
    case Delega.UserCache.get(team_id)
         |> Map.has_key?(user_id) do
      true ->
        true

      false ->
        Delega.UserCache.load_and_get(team)
        |> Map.has_key?(user_id)
    end
  end

  def validate_and_welcome(user_id, team) do
    # First check in the database
    user = User |> Repo.get(user_id)

    case user do
      nil ->
        # Check in the cache
        user =
          case Delega.UserCache.get(team.team_id)
               |> Map.get(user_id) do
            # Check in the API
            nil ->
              Delega.UserCache.load_and_get(team)
              |> Map.get(user_id)

            user ->
              user
          end

        case user do
          nil ->
            false

          user ->
            user = Map.merge(%User{}, user)

            user =
              case team.bot_access_token do
                nil ->
                  user

                _ ->
                  %{
                    user
                    | :channel_id =>
                        Interactive.get_user_channel(team.bot_access_token, user.user_id)
                  }
              end

            user = Repo.insert!(user, returning: true)

            Task.start(fn -> Interactive.send_welcome_msg(user, team) end)

            true
        end

      # User already exists in database
      # No need to welcome
      _ ->
        true
    end
  end

  def load_and_get(%{team_id: team_id, access_token: _} = team) do
    Delega.UserCache.load_from_slack(team)
    Delega.UserCache.safe_get(team_id)
  end

  def handle_call({:get, team_id}, _from, state) do
    {:reply, Delega.UserCache.get(team_id), state}
  end

  def handle_cast({:put, key, data}, state) do
    :ets.insert(:user_cache, {key, data})
    {:noreply, state}
  end
end
