defmodule Delega.Repo do
  use Ecto.Repo,
    otp_app: :delega,
    adapter: Ecto.Adapters.Postgres
end
