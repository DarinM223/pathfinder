defmodule Pathfinder.WorkerTest do
  use ExUnit.Case

  alias Pathfinder.Stash

  setup context do
    registry = :"#{context.test}_registry"
    {:ok, _} = Registry.start_link(keys: :unique, name: registry)
    {:ok, stash} = Stash.start_link(name: :"#{context.test}_stash")
    worker = "#{context.test}_worker"

    {:ok, stash: stash, registry: registry, worker: worker}
  end

  test "loads game state if in stash", %{stash: stash, registry: registry, worker: worker} do
    id = {registry, worker}
    Stash.set(stash, worker, :game)

    {:ok, _} = Pathfinder.Worker.start_link([id, stash, {0, -1}])
    assert Pathfinder.state(id) == :game
  end

  test "worker accepts build and turn messages", %{
    stash: stash,
    registry: registry,
    worker: worker
  } do
    id = {registry, worker}
    {:ok, _} = Pathfinder.Worker.start_link([id, stash, {0, 1}])

    changes = [
      {:place_goal, [{2, 2}]},
      {:set_wall, [{1, 1}, {2, 1}, true]}
    ]

    :ok = Pathfinder.build(id, 0, changes)
    {:turn, player} = Pathfinder.build(id, 1, changes)

    {:turn, player} = Pathfinder.turn(id, player, {:place_player, [2]})
    {:turn, player} = Pathfinder.turn(id, player, {:place_player, [2]})

    {:error, player} = Pathfinder.turn(id, player, {:move_player, [1]})
    {:error, player} = Pathfinder.turn(id, player, {:move_player, [1]})

    assert {:win, ^player} = Pathfinder.turn(id, player, {:move_player, [2]})
  end
end
