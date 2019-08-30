defmodule DelegaWeb.OAuthController do
  use DelegaWeb, :controller

  alias Delega.Repo
  alias Delega.Team

  def index(conn, %{"code" => code}) do
    client_id = Application.get_env(:delega, :slack_client_id)
    client_secret = Application.get_env(:delega, :slack_client_secret)

    # get auth token from API
    %{"team_id" => team_id, "access_token" => access_token} =
      Slack.API.oauth_access(%{client_id: client_id, client_secret: client_secret, code: code})
      |> Map.get(:body)
      |> Jason.decode!()

    # store auth token
    Repo.insert(%Team{team_id: team_id, access_token: access_token},
      on_conflict: [set: [access_token: access_token]],
      conflict_target: :team_id
    )

    # pull users
    Delega.UserCache.load_from_slack(%{team_id: team_id, access_token: access_token})

    render(conn, "oauth_success.html")
  end

  def index(conn, %{"error" => "access_denied"}) do
    render(conn, "oauth_failure.html")
  end
end
