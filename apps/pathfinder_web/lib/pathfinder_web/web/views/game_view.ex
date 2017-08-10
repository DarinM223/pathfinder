defmodule PathfinderWeb.Web.GameView do
  use PathfinderWeb.Web, :view

  alias PathfinderWeb.Web.Router

  def player_id(conn) do
    if conn.assigns.current_user do
      conn.assigns.current_user.id
    else
      -1
    end
  end

  def share_link(conn, game) do
    if conn.assigns.current_user.id == game.user_id and game.other_user_id == -1 do
      Router.Helpers.url(conn) <> "/play/#{game.shareid}"
    else
      nil
    end
  end
end
