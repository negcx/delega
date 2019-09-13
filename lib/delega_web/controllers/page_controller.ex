defmodule DelegaWeb.PageController do
  use DelegaWeb, :controller

  @client_id Application.get_env(:delega, :slack_client_id)

  def index(conn, _params) do
    render(conn, "index.html", client_id: @client_id)
  end

  def oauth_failure(conn, _params) do
    render(conn, "oauth_failure.html", client_id: @client_id)
  end

  def loader_io(conn, _params) do
    conn |> send_resp(200, "loaderio-5c5817b4751c09eb622cccc517a55ff5")
  end

  def oauth_success(conn, _params) do
    render(conn, "oauth_success.html")
  end
end
