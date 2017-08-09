defmodule PathfinderWeb.Web.PlayController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def show(conn, %{"shareid" => shareid}) do
    game = Data.get_shared_game!(shareid)

    cond do
      conn.assigns.current_user != nil and
      conn.assigns.current_user.id == game.other_user_id ->
        render conn, "show.html", game: game, token: nil
      game.other_user_id == -1 and conn.assigns.current_user == nil ->
        token =
          if not game.accessed do
            {:ok, _} = Data.update_game(game, %{accessed: true})
            Phoenix.Token.sign(conn, "non-logged-in-user socket", game.shareid)
          else
            nil
          end
        render conn, "show.html", game: game, token: token
      true ->
        render conn, "show.html", game: game, token: nil
    end
  end
end
