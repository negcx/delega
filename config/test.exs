use Mix.Config

config :delega, slack_base_url: "http://localhost:8081/"

# Configure your database
config :delega, Delega.Repo,
  username: "postgres",
  password: "postgres",
  database: "delega_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :delega, DelegaWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
