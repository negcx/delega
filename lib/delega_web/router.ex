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
    plug Slack.SignaturePlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DelegaWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/oauth", OAuthController, :index
  end

  scope "/slack", DelegaWeb do
    pipe_through :slack

    post "/slash", SlashController, :slash
    post "/slash/delega-list", SlashController, :delega_list
    post "/interactivity", SlashController, :interactivity
  end
end
