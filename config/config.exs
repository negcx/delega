# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :delega,
  ecto_repos: [Delega.Repo]

# Reminders
config :delega, Delega.Reminders,
  jobs: [
    # Configure the job to run every hour to send reminders
    # at 9 in the morning
    {"0 * * * *", {Delega.Reminders, :send_reminders, [9, 0]}}
  ]

# Configures the endpoint
config :delega, DelegaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "VCRnVahzmz/F7fi+Ajq61RIwelbQMQ2W98jaRXRhrMdq2iriG/Hc1ENG5D9PhHbx",
  render_errors: [view: DelegaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Delega.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :delega, signing_secret: System.get_env("SLACK_SIGNING_SECRET")
config :delega, slack_client_secret: System.get_env("SLACK_CLIENT_SECRET")
config :delega, slack_client_id: System.get_env("SLACK_CLIENT_ID")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
