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

  post "/im.open" do
    conn
    |> send_resp(
      200,
      Jason.encode!(%{
        "channel" => %{
          "id" => "Some ID"
        }
      })
    )
  end

  post "/oauth.access" do
    conn |> send_resp(200, "")
  end

  get "/users.list" do
    conn
    |> send_resp(
      200,
      Jason.encode!(%{
        "ok" => true,
        "members" => [
          %{
            "id" => "Kyle",
            "tz_offset" => -25200,
            "deleted" => false,
            "profile" => %{
              "display_name_normalized" => "kylesito"
            }
          },
          %{
            "id" => "Gely",
            "tz_offset" => -25200,
            "deleted" => false,
            "profile" => %{
              "display_name_normalized" => "gelita"
            }
          }
        ],
        "response_metadata" => %{"next_cursor" => ""}
      })
    )
  end

  post "/response_url" do
    conn |> send_resp(200, "")
  end
end
