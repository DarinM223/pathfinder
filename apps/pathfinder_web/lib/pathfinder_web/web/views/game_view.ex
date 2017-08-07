defmodule PathfinderWeb.Web.GameView do
  use PathfinderWeb.Web, :view

  def player_id(conn) do
    if conn.assigns.current_user do
      conn.assigns.current_user.id
    else
      -1
    end
  end

  def share_link(conn, game) do
    PathfinderWeb.Web.Router.Helpers.url(conn) <> "/play/#{game.shareid}"
  end
end
