defmodule DelegaWeb.EventsController do
  use DelegaWeb, :controller

  alias Delega.{Repo, Team, UserCache}

  def event(
        conn,
        %{"type" => "url_verification", "challenge" => challenge}
      ) do
    conn |> send_resp(200, challenge)
  end

  def event(
        conn,
        %{"event" => %{"type" => "app_home_opened", "user" => user_id}, "team_id" => team_id}
      ) do
    team = Repo.get!(Team, team_id)

    UserCache.validate_and_welcome(user_id, team)

    conn |> send_resp(200, "")
  end
end
