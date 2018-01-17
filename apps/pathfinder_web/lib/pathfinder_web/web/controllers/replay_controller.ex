defmodule PathfinderWeb.Web.ReplayController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  plug(:authenticate_user when action in [:index])

  def index(conn, _) do
    games = Data.list_user_created_games(conn.assigns.current_user, true)
    render(conn, "index.html", games: games)
  end

  def show(conn, %{"id" => id}) do
    game = Data.get_game!(id)

    if game.winner != nil do
      changes = Data.list_changes(game)
      render(conn, "show.html", changes: changes)
    else
      conn
      |> put_flash(:error, "Can only view the replay of a completed game")
      |> redirect(to: page_path(conn, :index))
    end
  end
end
