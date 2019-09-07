defmodule Slack.API do
  @base_url Application.get_env(:delega, :slack_base_url)

  def post_message(%{token: token, channel: channel, text: text, blocks: blocks}) do
    HTTPoison.post!(
      @base_url <> "chat.postMessage",
      Jason.encode!(%{
        "channel" => channel,
        "text" => text,
        "blocks" => blocks
      }),
      [
        {"Authorization", "Bearer " <> token},
        {"Content-Type", "application/json"}
      ]
    )
  end

  def oauth_access(%{client_id: client_id, client_secret: client_secret, code: code}) do
    HTTPoison.post!(
      @base_url <> "oauth.access",
      {:form, [{"code", code}]},
      [],
      hackney: [basic_auth: {client_id, client_secret}]
    )
  end

  def get_users(token) do
    HTTPoison.get!(@base_url <> "users.list", [
      {"Authorization", "Bearer " <> token}
    ])
  end

  def get_channels(token) do
    HTTPoison.get!(
      @base_url <> "conversations.list",
      [
        {"Authorization", "Bearer " <> token}
      ],
      params: %{
        "limit" => 1000,
        "exclude_archived" => true,
        "types" => "public_channel,private_channel"
      }
    )
    |> Map.get(:body)
    |> Jason.decode!()
    |> Map.get("channels")
  end

  def parse_channels(text) do
    channels_re = ~r/(?<=<#)([A-Z0-9]+)/

    channels_re
    |> Regex.scan(text)
    |> Enum.map(&hd/1)
  end

  def parse_users(text) do
    users_re = ~r/(?<=<@)([A-Z0-9]+)/

    users_re
    |> Regex.scan(text)
    |> Enum.map(&hd/1)
  end
end
