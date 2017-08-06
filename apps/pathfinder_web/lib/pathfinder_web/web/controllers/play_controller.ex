defmodule PathfinderWeb.Web.PlayController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def show(conn, %{"shareid" => shareid}) do
    game = Data.get_shared_game!(shareid)
    render conn, "show.html", game: game
  end
end
