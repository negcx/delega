defmodule Slack.SignaturePlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    signing_secret = Application.get_env(:delega, :signing_secret)

    slack_version = "v0"
    slack_request_timestamp = conn |> get_req_header("x-slack-request-timestamp") |> hd
    slack_signature = conn |> get_req_header("x-slack-signature") |> hd

    body = conn.assigns[:raw_body] |> hd

    data = slack_version <> ":" <> slack_request_timestamp <> ":" <> body

    calculated_signature =
      :crypto.hmac(:sha256, signing_secret, data)
      |> Base.encode16()
      |> String.downcase()

    calculated_signature = "v0=" <> calculated_signature

    if calculated_signature == slack_signature do
      conn
    else
      conn |> send_resp(400, "Invalid signature")
    end
  end
end
