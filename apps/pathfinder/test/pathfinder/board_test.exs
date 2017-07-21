defmodule Pathfinder.BoardTest do
  use ExUnit.Case, async: true
  doctest Pathfinder.Board

  alias Pathfinder.Board

  test "to_io_list/1 returns the correct output with empty board" do
    expected =
      """
      +---+---+---+---+---+---+
                              |
      +   +   +   +   +   +   +
                              |
      +   +   +   +   +   +   +
                              |
      +   +   +   +   +   +   +
                              |
      +   +   +   +   +   +   +
                              |
      +   +   +   +   +   +   +
                              |
      +---+---+---+---+---+---+
      """
    result =
      Board.new()
      |> Board.to_io_list()
      |> Enum.join()

    assert result == expected
  end
end
