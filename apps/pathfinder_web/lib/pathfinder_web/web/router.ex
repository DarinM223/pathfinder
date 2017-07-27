defmodule PathfinderWeb.Web.Router do
  use PathfinderWeb.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PathfinderWeb.Web.Auth, repo: PathfinderWeb.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PathfinderWeb.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/users", UserController, only: [:show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", PathfinderWeb.Web do
  #   pipe_through :api
  # end
end
