defmodule PathfinderWeb.Web.PlayController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def show(conn, %{"shareid" => shareid}) do
    game = Data.get_shared_game!(shareid)

    token =
      if game.other_user_id == -1 and
         conn.assigns.current_user == nil and
         not game.accessed do
        {:ok, _} = Data.update_game(game, %{accessed: true})
        Phoenix.Token.sign(conn, "non-logged-in-user socket", game.shareid)
      else
        nil
      end

    render conn, "show.html", game: game, token: token
  end
end
