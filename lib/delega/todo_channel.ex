defmodule Delega.TodoChannel do
  use Ecto.Schema

  @primary_key false
  schema "todo_channel" do
    belongs_to :todo, Delega.Todo, references: :todo_id, type: :integer, primary_key: true

    field :channel_id, :string, primary_key: true

    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end

  def insert(todo_id, channel_id) do
    %Delega.TodoChannel{todo_id: todo_id, channel_id: channel_id}
    |> Delega.Repo.insert(on_conflict: :nothing)
  end
end
