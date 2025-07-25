defmodule Pathfinder.AITest do
  use ExUnit.Case, async: true

  alias Pathfinder.AI
  alias Pathfinder.Board

  @column_size Application.compile_env(:pathfinder, :column_size)

  test "move/2 with new AI attempts to place the player on a random row" do
    {_, true, move} = AI.move(AI.new(), Board.new())
    assert {:place_player, [row]} = move
    assert row >= 1 && row <= @column_size
  end

  test "move_success/3 with row placement move will push the row on the stack" do
    assert args = AI.move(AI.new(), Board.new())
    assert {ai, _, {:place_player, [row]}} = args
    assert Enum.empty?(ai.move_stack)

    ai = Kernel.apply(AI, :move_success, Tuple.to_list(args))
    assert ai.move_stack == [{row, 1}]
  end

  test "simulates ai in board and tests if it successfully reaches the goal" do
    for _ <- 1..100 do
      assert simulation(AI.new(), Board.new(), Board.generate())
    end
  end

  defp simulation(ai, seen_board, board) do
    args = AI.move(ai, seen_board)
    assert {ai, _, {fun, fun_args}} = args

    {ai, seen_board, board} =
      with {:ok, board} <- Kernel.apply(Board, fun, [board | fun_args]) do
        {:ok, seen_board} = Kernel.apply(Board, fun, [seen_board | fun_args])

        {
          Kernel.apply(AI, :move_success, Tuple.to_list(args)),
          seen_board,
          board
        }
      else
        _ -> {ai, seen_board, board}
      end

    if Board.player_location(board) == Board.goal_location(board) do
      true
    else
      simulation(ai, seen_board, board)
    end
  end
end
