defmodule Delega.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:todo_id, :id, autogenerate: true}
  schema "todo" do
    belongs_to :team, Delega.Team, references: :team_id, type: :string

    field :created_user_id, :string
    field :assigned_user_id, :string
    field :completed_user_id, :string

    field :todo, :string
    field :is_complete, :boolean

    field :completed_at, :utc_datetime_usec

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(cs, params \\ %{}) do
    cs
    |> cast(params, [:team_id, :created_user_id, :assigned_user_id, :task, :status])
    |> validate_required([:team_id, :created_user_id, :assigned_user_id, :task])
  end

  def complete(todo_id, user_id) do
    todo = %Delega.Todo{todo_id: todo_id}
    Ecto.Changeset.change(todo, is_complete: true, completed_user_id: user_id)
  end
end
