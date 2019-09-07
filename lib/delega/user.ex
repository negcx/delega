defmodule Delega.User do
  use Ecto.Schema

  @primary_key {:user_id, :string, autogenerate: false}
  schema "user_" do
    belongs_to :team, Delega.Team, references: :team_id, type: :string

    field :tz_offset, :integer
    field :display_name, :string
    field :is_deleted, :boolean

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end
