defmodule Pathfinder.Player do
  alias Pathfinder.Board

  @doc """
  Returns a new player.
  """
  def new do
    %{board: Board.new(),
      enemy_board: Board.new()}
  end
end
