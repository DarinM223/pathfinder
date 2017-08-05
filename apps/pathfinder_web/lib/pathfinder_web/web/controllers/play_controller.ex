defmodule PathfinderWeb.Web.PlayController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def show(conn, %{"id" => id}) do
    game = Data.get_game!(id)
    render conn, "show.html", game: game
  end
end
