defmodule Delega.TodoAssignment do
  use Ecto.Schema

  alias Delega.Todo

  @primary_key {:todo_assignment_id, :id, autogenerate: true}
  schema "todo_assignment" do
    field :assigned_to_user_id, :string
    field :assigned_by_user_id, :string

    belongs_to :todo, Todo, references: :todo_id, foreign_key: :todo_id

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
