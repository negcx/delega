defmodule Delega.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  alias Delega.{Todo, Repo}

  import Ecto.Query, only: [from: 2]

  @primary_key {:todo_id, :id, autogenerate: true}
  schema "todo" do
    belongs_to :team, Delega.Team, references: :team_id, type: :string

    field :created_user_id, :string
    field :assigned_user_id, :string
    field :completed_user_id, :string
    field :rejected_user_id, :string

    field :todo, :string
    field :status, :string

    field :completed_at, :utc_datetime_usec
    field :rejected_at, :utc_datetime_usec

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def changeset(cs, params \\ %{}) do
    cs
    |> cast(params, [:team_id, :created_user_id, :assigned_user_id, :task, :status])
    |> validate_required([:team_id, :created_user_id, :assigned_user_id, :task])
  end

  def complete!(todo, completed_user_id) do
    todo = Ecto.Changeset.change(todo, status: "COMPLETE", completed_user_id: completed_user_id)
    Delega.Repo.update!(todo)
  end

  def reject!(todo, rejected_user_id) do
    todo = Ecto.Changeset.change(todo, status: "REJECTED", rejected_user_id: rejected_user_id)
    Delega.Repo.update!(todo)
  end

  def get_todo_list(user_id) do
    Repo.all(
      from t in Todo,
        where:
          t.assigned_user_id == ^user_id and
            t.status == "NEW"
    )
  end

  def get_delegation_list(user_id) do
    Repo.all(
      from t in Todo,
        where:
          t.status == "NEW" and
            t.created_user_id == ^user_id and
            t.assigned_user_id != ^user_id
    )
  end
end
