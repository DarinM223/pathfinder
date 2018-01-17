defmodule PathfinderWeb.Web.BoardView do
  use PathfinderWeb.Web, :view

  alias Pathfinder.Board

  def render("board.json", %{board: board}) do
    cells =
      for row <- 1..6,
          col <- 1..6 do
        index = Board.index(row, col)
        cell = Map.get(board, index)

        cell_json(row, col, cell)
      end

    player =
      with {:ok, {row, col}} <- Map.fetch(board, :player),
           do: [row - 1, col - 1],
           else: (_ -> nil)

    goal =
      with {:ok, {row, col}} <- Map.fetch(board, :goal),
           do: [row - 1, col - 1],
           else: (_ -> nil)

    %{
      player: player,
      goal: goal,
      cells: cells
    }
  end

  def cell_json(row, col, {data, top, right, bottom, left}) do
    %{
      data: data,
      row: row - 1,
      col: col - 1,
      top: top,
      right: right,
      bottom: bottom,
      left: left
    }
  end
end
