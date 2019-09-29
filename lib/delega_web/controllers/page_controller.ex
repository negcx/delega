defmodule DelegaWeb.PageController do
  use DelegaWeb, :controller

  @client_id Application.get_env(:delega, :slack_client_id)

  alias Delega.{Repo, Team, User, Todo}

  import Ecto.Query, only: [from: 2]

  def index(conn, _params) do
    render(conn, "index.html", client_id: @client_id)
  end

  def oauth_failure(conn, _params) do
    render(conn, "oauth_failure.html", client_id: @client_id)
  end

  def oauth_success(conn, _params) do
    render(conn, "oauth_success.html")
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html")
  end

  def stats(conn, _params) do
    team_count = Repo.aggregate(Team, :count, :team_id)
    user_count = Repo.aggregate(User, :count, :user_id)
    todo_count = Repo.aggregate(Todo, :count, :todo_id)

    completed_todos =
      Repo.aggregate(
        from(t in Todo,
          where: t.status == "COMPLETE"
        ),
        :count,
        :todo_id
      )

      rejected_todos =
      Repo.aggregate(
        from(t in Todo,
          where: t.status == "REJECTED"
        ),
        :count,
        :todo_id
      )


    users_created_todos =
      Repo.aggregate(
        from(t in Todo,
          distinct: t.created_user_id
        ),
        :count,
        :created_user_id
      )

    users_completed_todos =
      Repo.aggregate(
        from(t in Todo,
          distinct: t.completed_user_id
        ),
        :count,
        :completed_user_id
      )

    render(conn, "stats.html",
      team_count: team_count,
      user_count: user_count,
      todo_count: todo_count,
      users_created_todos: users_created_todos,
      users_completed_todos: users_completed_todos,
      completed_todos: completed_todos,
      rejected_todos: rejected_todos
    )
  end
end
