defmodule DelegaWeb.EventsController do
  use DelegaWeb, :controller

  alias Delega.{Repo, User}
  alias Delega.Slack.{Interactive}

  def event(
        conn,
        %{"type" => "url_verification", "challenge" => challenge}
      ) do
    conn |> send_resp(200, challenge)
  end

  def event(
        conn,
        %{"event" => %{"type" => "app_home_opened", "user" => user_id, "channel" => _channel_id}}
      ) do
    user = Repo.get!(User, user_id) |> Repo.preload(:team)

    Interactive.send_welcome_msg(user, user.team)

    conn |> send_resp(200, "")
  end
end
