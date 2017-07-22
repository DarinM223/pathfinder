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

    assert Board.set_wall(Board.new(), cell1, cell2, true) == :error
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

  test "place_player/2 returns error if wall is blocked" do
    {:ok, board} = Board.set_wall(Board.new(), 1, true)
    assert {:error, :wall} = Board.place_player(board, 1)
  end

  test "place_player/2 properly places player at row entry" do
    {:ok, board} = Board.place_player(Board.new(), 1)
    assert {row, col} = Map.get(board, :player)
    index = Board.index(row, col)
    assert {:player, _, _, _, _} = Map.get(board, index)
  end

  test "place_goal/2 properly places goal at position" do
    goal_pos = {3, 4}
    {:ok, board} = Board.place_goal(Board.new(), goal_pos)
    assert Map.get(board, :goal) == goal_pos
    index = Board.index(goal_pos)
    assert {:goal, _, _, _, _} = Map.get(board, index)
  end

  test "remove_player/1 fails if player is not on board" do
    assert Board.remove_player(Board.new()) == :error
  end

  test "remove_player/1 fails if player is not next to a row entry" do
    board = Map.put(Board.new(), :player, {3, 4})
    assert Board.remove_player(board) == :error
  end

  test "remove_player/1 fails if row entry has a left wall" do
    {:ok, board} = Board.place_player(Board.new(), 1)
    {:ok, board} = Board.set_wall(board, 1, true)
    assert Board.remove_player(board) == :error
  end

  test "remove_player/1 properly removes player" do
    {:ok, board} = Board.place_player(Board.new(), 1)
    {:ok, board} = Board.remove_player(board)
    assert Map.get(board, :player) == nil
    assert {:marker, _, _, _, _} = Map.get(board, Board.index(1, 1))
  end

  test "move_player/2 fails if player tries to move outside left side of grid" do
    {:ok, board} = Board.place_player(Board.new(), 1)
    assert Board.move_player(board, 4) == :error
  end

  test "move_player/2 fails if player tries to move through wall" do
    {:ok, board} = Board.place_player(Board.new(), 1)
    {:ok, board} = Board.set_wall(board, {1, 1}, {1, 2}, true)
    assert Board.move_player(board, 2) == :error
  end

  test "move_player/2 properly moves player" do
    {:ok, board} = Board.place_player(Board.new(), 1)
    {:ok, board} = Board.move_player(board, 2)
    assert Map.get(board, :player) == {1, 2}
    assert {:marker, _, _, _, _} = Map.get(board, Board.index(1, 1))
    assert {:player, _, _, _, _} = Map.get(board, Board.index(1, 2))
  end
end
