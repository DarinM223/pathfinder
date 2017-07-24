defmodule Pathfinder.WorkerTest do
  use ExUnit.Case

  alias Pathfinder.Store
  alias Pathfinder.Store.Ets
  alias Pathfinder.Worker

  test "should load game state if in ets" do
    store = Ets.new(:table)
    {:ok, _} = Registry.start_link(:unique, :game_registry)

    Store.set(store, "blah", :game)

    {:ok, _} = Pathfinder.Worker.start_link(:game_registry, store, "blah")
    assert Pathfinder.Worker.state(:game_registry, "blah") == :game
  end
end
