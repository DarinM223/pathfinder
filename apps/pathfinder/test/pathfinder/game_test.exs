defmodule Pathfinder.GameTest do
  use ExUnit.Case

  alias Pathfinder.Game
  alias Pathfinder.Board
  alias Pathfinder.Player

  test "build/3 should ignore unallowed build actions" do
    changes = [{:bleargh, []},
               {:remove_player, []},
               {:place_player, [1]},
               {:move_player, [2]},
               {:place_goal, [{3, 4}]},
               {:set_wall, [1, true]}]
    {:ok, game} = Game.build(Game.new(), 1, changes)

    {:ok, board} = Board.place_goal(Board.new(), {3, 4})
    {:ok, board} = Board.set_wall(board, 1, true)

    expected_game = %{
      state: {:build, 1},
      players: %{0 => Player.new(),
                 1 => %{Player.new() | board: board}}
    }

    assert game == expected_game
  end

  test "build/3 should return error for invalid boards" do
    changes = [{:place_goal, [{3, 4}]},
               {:set_wall, [{2, 4}, {3, 4}, true]},
               {:set_wall, [{3, 3}, {3, 4}, true]},
               {:set_wall, [{3, 5}, {3, 4}, true]},
               {:set_wall, [{4, 4}, {3, 4}, true]}]
    assert Game.build(Game.new(), 1, changes) == :error
  end

  test "build/3 should change state to :turn once both players are finished" do
    p1_changes = [{:place_goal, [{3, 4}]}]
    p2_changes = [{:place_goal, [{2, 4}]}]

    {:ok, game} = Game.build(Game.new(), 0, p1_changes)
    {:ok, game} = Game.build(game, 1, p2_changes)

    {:ok, p1_board} = Board.place_goal(Board.new(), {3, 4})
    {:ok, p2_board} = Board.place_goal(Board.new(), {2, 4})

    assert game.state == {:turn, 0} or game.state == {:turn, 1}
    assert game.players == %{0 => %{Player.new() | board: p1_board},
                             1 => %{Player.new() | board: p2_board}}
  end

  test "turn/3 should update the player's enemy board and the enemy's board" do
    changes = [{:place_goal, [{3, 4}]}]

    {:ok, game} = Game.build(Game.new(), 0, changes)
    {:ok, game} = Game.build(game, 1, changes)

    {:turn, player} = Game.state(game)
    {:ok, game} = Game.turn(game, player, {:place_player, [1]})

    enemy = if player == 0, do: 1, else: 0
    player_enemy_board = get_in(game, [:players, player, :enemy_board])
    enemy_board = get_in(game, [:players, enemy, :board])

    assert Board.player_location(player_enemy_board) == {1, 1}
    assert Board.player_location(enemy_board) == {1, 1}
  end

  test "turn/3 should add a wall to player's enemy board if place_player fails" do
    changes = [{:place_goal, [{3, 4}]}, {:set_wall, [1, true]}]

    {:ok, game} = Game.build(Game.new(), 0, changes)
    {:ok, game} = Game.build(game, 1, changes)

    {:turn, player} = Game.state(game)
    {:error, game} = Game.turn(game, player, {:place_player, [1]})

    player_enemy_board = get_in(game, [:players, player, :enemy_board])

    assert {_, _, _, _, true} = Map.get(player_enemy_board, Board.index(1, 1))
  end

  test "turn/3 should add a wall to player's enemy board if remove_player fails" do
    changes = [{:place_goal, [{3, 4}]}, {:set_wall, [1, true]}]

    {:ok, game} = Game.build(Game.new(), 0, changes)
    {:ok, game} = Game.build(game, 1, changes)

    {:turn, player} = Game.state(game)
    enemy = if player == 0, do: 1, else: 0

    {:ok, game} = Game.turn(game, player, {:place_player, [2]})
    {:ok, game} = Game.turn(game, enemy, {:place_player, [2]})
    {:ok, game} = Game.turn(game, player, {:move_player, [1]})
    {:ok, game} = Game.turn(game, enemy, {:move_player, [1]})

    {:error, game} = Game.turn(game, player, {:remove_player, []})
    player_enemy_board = get_in(game, [:players, player, :enemy_board])

    assert {_, _, _, _, true} = Map.get(player_enemy_board, Board.index(1, 1))
  end

  test "turn/3 should add a wall to player's enemy board if move_player fails" do
    changes = [{:place_goal, [{3, 4}]}, {:set_wall, [{2, 2}, {3, 2}, true]}]

    {:ok, game} = Game.build(Game.new(), 0, changes)
    {:ok, game} = Game.build(game, 1, changes)

    {:turn, player} = Game.state(game)
    enemy = if player == 0, do: 1, else: 0

    {:ok, game} = Game.turn(game, player, {:place_player, [2]})
    {:ok, game} = Game.turn(game, enemy, {:place_player, [2]})
    {:ok, game} = Game.turn(game, player, {:move_player, [2]})
    {:ok, game} = Game.turn(game, enemy, {:move_player, [2]})

    {:error, game} = Game.turn(game, player, {:move_player, [3]})
    player_enemy_board = get_in(game, [:players, player, :enemy_board])

    assert {_, _, _, true, _} = Map.get(player_enemy_board, Board.index(2, 2))
  end

  test "turn/3 should return a win if the player lands on the goal" do
    changes = [{:place_goal, [{2, 2}]}]

    {:ok, game} = Game.build(Game.new(), 0, changes)
    {:ok, game} = Game.build(game, 1, changes)

    {:turn, player} = Game.state(game)
    enemy = if player == 0, do: 1, else: 0

    {:ok, game} = Game.turn(game, player, {:place_player, [2]})
    {:ok, game} = Game.turn(game, enemy, {:place_player, [2]})

    assert {:win, ^player, _} = Game.turn(game, player, {:move_player, [2]})
  end
end
