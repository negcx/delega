defmodule Delega.Feedback do
  use Ecto.Schema

  @primary_key {:feedback_id, :id, autogenerate: true}
  schema "feedback" do
    belongs_to :user, Delega.User, references: :user_id, foreign_key: :user_id, type: :string

    field :feedback, :string

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end
