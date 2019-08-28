defmodule DelegaWeb.PageController do
  use DelegaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
