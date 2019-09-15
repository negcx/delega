defmodule Delega.TodoAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:todo_assignment_id, :id, autogenerate: true}
  schema "todo_assignment" do
    belongs_to :todo, Delega.Todo, references: :todo_id, type: :integer

    field :assigned_to_user_id, :string
    field :assigned_by_user_id, :string

    has_one :assigned_to_user, Delega.User,
      references: :assigned_to_user_id,
      foreign_key: :user_id

    has_one :assigned_by_user, Delega.User,
      references: :assigned_by_user_id,
      foreign_key: :user_id

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end
end
