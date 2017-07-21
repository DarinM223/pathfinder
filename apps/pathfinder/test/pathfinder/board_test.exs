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

  test "set_wall/4 with non-adjacent cells" do
    cell1 = {6, 6}
    cell2 = {6, 4}

    assert {:error, :invalid_cells} = Board.set_wall(Board.new(), cell1, cell2, true)
  end

  test "set_wall/4 with top or bottom adjacency" do
    cell1 = {4, 3}
    cell2 = {5, 3}
    {index1, index2} = {Board.index(cell1), Board.index(cell2)}

    {:ok, board} = Board.set_wall(Board.new(), cell1, cell2, true)
    assert {_, false, false, true, false} = Map.get(board, index1)
    assert {_, true, false, false, false} = Map.get(board, index2)

    {:ok, board} = Board.set_wall(Board.new(), cell2, cell1, true)
    assert {_, false, false, true, false} = Map.get(board, index1)
    assert {_, true, false, false, false} = Map.get(board, index2)
  end

  test "set_wall/4 with left or right adjacency" do
    cell1 = {3, 5}
    cell2 = {3, 4}
    {index1, index2} = {Board.index(cell1), Board.index(cell2)}

    {:ok, board} = Board.set_wall(Board.new(), cell1, cell2, true)
    assert {_, false, false, false, true} = Map.get(board, index1)
    assert {_, false, true, false, false} = Map.get(board, index2)

    {:ok, board} = Board.set_wall(Board.new(), cell2, cell1, true)
    assert {_, false, false, false, true} = Map.get(board, index1)
    assert {_, false, true, false, false} = Map.get(board, index2)
  end

  test "set_wall/4 can remove existing walls" do
    cell1 = {3, 5}
    cell2 = {3, 4}

    {:ok, board} = Board.set_wall(Board.new(), cell1, cell2, true)
    {:ok, board} = Board.set_wall(board, cell1, cell2, false)

    assert board == Board.new()
  end

  test "set_wall/3 sets the row entry wall" do
    row = 3
    index = Board.index({row, 1})

    {:ok, board} = Board.set_wall(Board.new(), row, true)
    assert {_, false, false, false, true} = Map.get(board, index)

    {:ok, board} = Board.set_wall(board, row, false)
    assert board == Board.new()
  end
end
