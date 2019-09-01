defmodule Delega.UserCache do
  use GenServer

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
    users =
      Slack.API.get_users(access_token)
      |> Map.get(:body)
      |> Jason.decode!()
      |> Map.get("members")
      |> Enum.reduce(Map.new(), fn user, map ->
        Map.put(map, Map.get(user, "id"), %{
          user_id: Map.get(user, "id"),
          tz_offset: Map.get(user, "tz_offset")
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
