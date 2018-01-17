defmodule Pathfinder.Player do
  alias Pathfinder.Board

  @doc """
  Returns a new player.
  """
  def new do
    %{
      board: Board.new(),
      enemy_board: Board.new()
    }
  end

  @doc """
  Returns the console printable version of the player as an IO list.
  """
  def to_io_list(player) do
    [
      "Board:\n",
      Board.to_io_list(player.board),
      "Enemy board:\n",
      Board.to_io_list(player.enemy_board)
    ]
  end
end
