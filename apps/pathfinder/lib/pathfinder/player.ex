defmodule Pathfinder.Player do
  alias Pathfinder.Board

  defstruct board: Board.new(), enemy_board: Board.new()
end
