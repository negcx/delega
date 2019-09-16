defmodule Delega.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  alias Delega.{Todo, Repo, TodoAssignment}

  import Ecto.Query, only: [from: 2]

  @primary_key {:todo_id, :id, autogenerate: true}
  schema "todo" do
    belongs_to :team, Delega.Team, references: :team_id, type: :string

    has_many :channels, Delega.TodoChannel, foreign_key: :todo_id

    field :created_user_id, :string
    field :assigned_user_id, :string
    field :completed_user_id, :string
    field :rejected_user_id, :string

    has_one :created_user, Delega.User, references: :created_user_id, foreign_key: :user_id
    has_one :assigned_user, Delega.User, references: :assigned_user_id, foreign_key: :user_id
    has_one :completed_user, Delega.User, references: :completed_user_id, foreign_key: :user_id
    has_one :rejected_user, Delega.User, references: :rejected_user_id, foreign_key: :user_id

    has_many :assignments, Delega.TodoAssignment, foreign_key: :todo_id

    field :todo, :string
    field :status, :string

    field :completed_at, :utc_datetime_usec
    field :rejected_at, :utc_datetime_usec

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  @preload [
    :completed_user,
    :created_user,
    :rejected_user,
    :channels,
    [assignments: from(TodoAssignment, order_by: [:created_at], preload: :assigned_to_user)],
    :assigned_user
  ]

  def changeset(cs, params \\ %{}) do
    cs
    |> cast(params, [:team_id, :created_user_id, :assigned_user_id, :task, :status])
    |> validate_required([:team_id, :created_user_id, :assigned_user_id, :task])
  end

  def complete!(todo, completed_user_id) do
    todo = Ecto.Changeset.change(todo, status: "COMPLETE", completed_user_id: completed_user_id)

    Delega.Repo.update!(todo, returning: true)
  end

  def reject!(todo, rejected_user_id) do
    todo = Ecto.Changeset.change(todo, status: "REJECTED", rejected_user_id: rejected_user_id)
    Delega.Repo.update!(todo, returning: true)
  end

  def reassign!(todo, by_user_id, to_user_id) do
    %TodoAssignment{assigned_to_user_id: to_user_id, assigned_by_user_id: by_user_id}
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:todo, todo)
    |> Repo.insert!()

    todo
    |> Ecto.Changeset.change(
      status: "NEW",
      assigned_user_id: to_user_id
    )
    |> Repo.update!()
  end

  def get_with_assoc(todo_id) do
    from(t in Todo,
      preload: ^@preload
    )
    |> Repo.get(todo_id)
  end

  def get_channel_todos(channel_id) do
    Repo.all(
      from t in Todo,
        join: c in assoc(t, :channels),
        where:
          c.channel_id == ^channel_id and
            t.status == "NEW",
        order_by: t.created_at,
        preload: ^@preload
    )
  end

  def get_assigned_todos(assigned_user_id) do
    Repo.all(
      from t in Todo,
        preload: ^@preload,
        where:
          t.assigned_user_id == ^assigned_user_id and
            t.status == "NEW",
        order_by: t.created_at
    )
  end

  def get_assigned_todos(assigned_user_id, channel_id) do
    Repo.all(
      from t in Todo,
        join: c in assoc(t, :channels),
        where:
          t.assigned_user_id == ^assigned_user_id and
            c.channel_id == ^channel_id and
            t.status == "NEW",
        order_by: t.created_at,
        preload: ^@preload
    )
  end

  def get_created_todos(created_user_id) do
    Repo.all(
      from t in Todo,
        preload: ^@preload,
        where:
          t.created_user_id == ^created_user_id and
            t.status == "NEW" and
            t.assigned_user_id != ^created_user_id,
        order_by: t.created_at
    )
  end

  def get_created_todos(created_user_id, channel_id) do
    Repo.all(
      from t in Todo,
        join: c in assoc(t, :channels),
        where:
          t.created_user_id == ^created_user_id and
            c.channel_id == ^channel_id and
            t.status == "NEW",
        preload: ^@preload,
        order_by: t.created_at
    )
  end
end
