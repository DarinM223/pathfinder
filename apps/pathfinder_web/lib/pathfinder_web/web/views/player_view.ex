defmodule PathfinderWeb.Web.PlayerView do
  use PathfinderWeb.Web, :view

  alias Pathfinder.Player

  def render("player.json", %{player: player}) do
    %{board: render_one(player.board, PathfinderWeb.Web.BoardView, "board.json"),
      enemy_board: render_one(player.enemy_board, PathfinderWeb.Web.BoardView, "board.json")}
  end
end
