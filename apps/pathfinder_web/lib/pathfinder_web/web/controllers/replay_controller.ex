defmodule PathfinderWeb.Web.ReplayController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def index(conn, _, user) do
    games = Data.list_user_created_games(user, true)
    render conn, "index.html", games: games
  end

  def show(conn, %{"id" => id}, user) do
    game = Data.get_user_game!(user, id)
    changes = Data.list_changes(game)
    render conn, "show.html", changes: changes
  end

  @doc """
  Default plug called by Phoenix framework that
  dispatches to the proper action.

  This is overwritten because we want to include the user as a
  parameter to the route functions.
  """
  def action(conn, _) do
    apply(__MODULE__, action_name(conn),
          [conn, conn.params, conn.assigns.current_user])
  end
end
