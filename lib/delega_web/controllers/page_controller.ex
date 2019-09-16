defmodule DelegaWeb.PageController do
  use DelegaWeb, :controller

  @client_id Application.get_env(:delega, :slack_client_id)

  def index(conn, _params) do
    render(conn, "index.html", client_id: @client_id)
  end

  def oauth_failure(conn, _params) do
    render(conn, "oauth_failure.html", client_id: @client_id)
  end

  def oauth_success(conn, _params) do
    render(conn, "oauth_success.html")
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html")
  end
end
