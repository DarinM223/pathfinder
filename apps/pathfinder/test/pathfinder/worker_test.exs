defmodule Pathfinder.WorkerTest do
  use ExUnit.Case

  alias Pathfinder.Store
  alias Pathfinder.Store.Ets
  alias Pathfinder.Worker

  setup context do
    registry = :"#{context.test}_registry"
    {:ok, _} = Registry.start_link(:unique, registry)
    store = Ets.new(:"#{context.test}_table")

    {:ok, store: store, registry: registry}
  end

  test "loads game state if in ets", %{store: store, registry: registry} do
    Store.set(store, "blah", :game)

    id = {registry, "blah"}
    {:ok, _} = Pathfinder.Worker.start_link(id, store)
    assert Pathfinder.state(id) == :game
  end

  test "worker accepts build and turn messages", %{store: store, registry: registry} do
    id = {registry, "blah"}
    {:ok, _} = Pathfinder.Worker.start_link(id, store)

    changes = [{:place_goal, [{2, 2}]},
               {:set_wall, [{1, 1}, {2, 1}, true]}]
    :ok = Pathfinder.build(id, 0, changes)
    {:turn, player} = Pathfinder.build(id, 1, changes)

    {:turn, player} = Pathfinder.turn(id, player, {:place_player, [2]})
    {:turn, player} = Pathfinder.turn(id, player, {:place_player, [2]})
    {:error, player} = Pathfinder.turn(id, player, {:move_player, [1]})
    {:error, player} = Pathfinder.turn(id, player, {:move_player, [1]})

    assert {:win, ^player} = Pathfinder.turn(id, player, {:move_player, [2]})
  end
end
