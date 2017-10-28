defmodule Pathfinder.AITest do
  use ExUnit.Case, async: true

  alias Pathfinder.AI
  alias Pathfinder.Board

  @column_size Application.get_env(:pathfinder, :column_size)

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
      assert _simulation(AI.new(), Board.generate())
    end
  end

  def _simulation(ai, board) do
    args = AI.move(ai, board)
    {_, _, {fun, fun_args}} = args

    ai = Kernel.apply(AI, :move_success, Tuple.to_list(args))
    {:ok, board} = Kernel.apply(Board, fun, [board | fun_args])

    if Board.player_location(board) == Board.goal_location(board) do
      true
    else
      _simulation(ai, board)
    end
  end
end
