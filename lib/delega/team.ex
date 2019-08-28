defmodule Delega.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:team_id, :string, autogenerate: false}
  schema "team" do
    field :access_token, :string

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(team, params \\ %{}) do
    team
    |> cast(params, [:team_id, :oauth_token])
    |> validate_required([:team_id, :oauth_token])
  end
end
