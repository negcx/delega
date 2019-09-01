defmodule DelegaWeb.PageController do
  use DelegaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", client_id: Application.get_env(:delega, :slack_client_id))
  end
end
