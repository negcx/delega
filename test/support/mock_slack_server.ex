defmodule Delega.MockSlackServer do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  post "/chat.postMessage" do
    conn |> send_resp(200, "")
  end

  post "/oauth.access" do
    conn |> send_resp(200, "")
  end

  post "/users.list" do
    conn |> send_resp(200, "")
  end

  post "/response_url" do
    conn |> send_resp(200, "")
  end
end
