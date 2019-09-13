defmodule DelegaWeb.Router do
  use DelegaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :slack do
    plug :accepts, ["json"]

    case Application.get_env(:delega, :env) do
      :test -> nil
      _ -> plug Slack.SignaturePlug
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DelegaWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/oauth", OAuthController, :index
    get "/oauth-failure", PageController, :oauth_failure
    get "/oauth-success", PageController, :oauth_success

    get "/loaderio-5c5817b4751c09eb622cccc517a55ff5", PageController, :loader_io
  end

  scope "/slack", DelegaWeb do
    pipe_through :slack

    post "/slash", SlashController, :slash
    post "/interactivity", SlashController, :interactivity
  end
end
