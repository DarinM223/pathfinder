defmodule PathfinderWeb.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use PathfinderWeb.Web, :controller
      use PathfinderWeb.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: PathfinderWeb.Web
      import Plug.Conn
      import PathfinderWeb.Web.Router.Helpers
      import PathfinderWeb.Web.Gettext

      import PathfinderWeb.Web.Auth, only: [authenticate_user: 2]
      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/pathfinder_web/web/templates",
        namespace: PathfinderWeb.Web

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PathfinderWeb.Web.Router.Helpers
      import PathfinderWeb.Web.ErrorHelpers
      import PathfinderWeb.Web.Gettext
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller

      import PathfinderWeb.Web.Auth, only: [authenticate_user: 2]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PathfinderWeb.Web.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PathfinderWeb.Web.Endpoint,
        router: PathfinderWeb.Web.Router,
        statics: PathfinderWeb.Web.static_paths()
    end
  end
end
