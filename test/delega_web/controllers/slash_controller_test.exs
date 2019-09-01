defmodule DelegaWeb.SlashControllerTest do
  use DelegaWeb.ConnCase, async: true

  alias Delega.{UserCache, Team, Todo, Repo}

  import Ecto.Query, only: [from: 2]

  def setup do
    team = %Team{team_id: "Delega", access_token: "a big secret"} |> Repo.insert!(returning: true)

    UserCache.put("Delega", %{"Kyle" => %{tz_offset: -21000}})

    team
  end

  test "/dg todo", %{conn: conn} do
    setup()

    conn = post(conn, "/slack/slash", text: "todo", user_id: "Kyle")

    json_response(conn, 200)
  end

  test "Add todos with slash command", %{conn: conn} do
    team = setup()

    conn =
      post(conn, "/slack/slash",
        text: "<@Kyle|kyle> My big todo",
        user_id: "Kyle",
        team_id: team.team_id,
        command: "/dg"
      )

    json_response(conn, 200)

    todo =
      from(t in Todo, where: t.todo == "My big todo")
      |> Repo.all()
      |> hd

    assert todo.todo_id > 0
    assert todo.created_user_id == "Kyle"
  end

  test "/dg help", %{conn: conn} do
    conn = post(conn, "/slack/slash", text: "help")

    json_response(conn, 200)
  end
end
