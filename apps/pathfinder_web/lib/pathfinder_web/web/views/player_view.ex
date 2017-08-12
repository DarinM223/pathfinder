defmodule PathfinderWeb.Web.PlayerView do
  use PathfinderWeb.Web, :view

  def render("player.json", %{id: id, player: player, state: state}) do
    state = Tuple.to_list(state)

    %{id: id,
      board: render_one(player.board, PathfinderWeb.Web.BoardView, "board.json"),
      enemy_board: render_one(player.enemy_board, PathfinderWeb.Web.BoardView, "board.json"),
      state: state}
  end
end
