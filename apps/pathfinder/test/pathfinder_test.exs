defmodule PathfinderTest do
  use ExUnit.Case
  doctest Pathfinder

  setup do
    Application.stop(:pathfinder)
    Application.start(:pathfinder)
  end

  test "add/2 adds the child", context do
    assert Pathfinder.add(context.test, 0, -1) == {:ok, {:game_registry, context.test}}
    assert is_map(Pathfinder.state({:game_registry, context.test}))
  end

  @tag :capture_log
  test "child saves to stash and restarts upon crash", context do
    {:ok, id} = Pathfinder.add(context.test, 0, 1)

    changes = [{:place_goal, [{2, 2}]}]
    :ok = Pathfinder.build(id, 0, changes)

    # Should crash worker.
    assert {:error, :timeout} = Pathfinder.turn(id, 0, {:move_player, [1]})

    # Check that the goal remains placed after restart.
    goal_location =
      Pathfinder.state(id)
      |> get_in([:players, 0, :board])
      |> Pathfinder.Board.goal_location()

    assert goal_location == {2, 2}
  end
end
