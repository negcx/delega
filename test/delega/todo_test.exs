defmodule Delega.TodoTest do
  use Delega.DataCase, async: true

  alias Delega.{Todo, Team, Repo, User, TodoAssignment, UserCache}

  setup do
    team =
      %Team{team_id: "Delega", access_token: "a big secret"}
      |> Repo.insert!(returning: true)

    UserCache.put("Delega", %{
      "fake user" => %{
        user_id: "fake user",
        team_id: "Delega",
        tz_offset: -25200
      }
    })

    user_kyle =
      %User{team_id: "Delega", user_id: "Kyle", tz_offset: -25200, display_name: "Kyle"}
      |> Repo.insert!(returning: true)

    user_gely =
      %User{team_id: "Delega", user_id: "gely", tz_offset: -25200, display_name: "gely"}
      |> Repo.insert!(returning: true)

    todo =
      %Todo{
        team_id: "Delega",
        created_user_id: "Kyle",
        assigned_user_id: "Kyle",
        todo: "Do some things",
        status: "NEW"
      }
      |> Repo.insert!(returning: true)

    %TodoAssignment{
      todo_id: todo.todo_id,
      assigned_to_user_id: "Kyle",
      assigned_by_user_id: "Kyle"
    }
    |> Repo.insert!()

    [todo: todo, team: team, user_kyle: user_kyle, user_gely: user_gely]
  end

  test "reassign todo", %{todo: todo, user_gely: user_gely, user_kyle: user_kyle} do
    Todo.reassign!(todo, user_kyle.user_id, user_gely.user_id)

    updated_todo = Todo.get_with_assoc(todo.todo_id)

    assert updated_todo.assigned_user_id == user_gely.user_id
    assert length(updated_todo.assignments) == 2
  end
end
