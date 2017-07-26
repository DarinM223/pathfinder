defmodule Pathfinder.StashTest do
  use ExUnit.Case
  alias Pathfinder.Stash

  setup context do
    {:ok, stash} = Stash.start_link([name: :"#{context.test}_stash"])
    {:ok, stash: stash}
  end

  test "get/set in stash", %{stash: stash} do
    value = %{"hello" => true, a: [1, 2]}
    assert Stash.get(stash, "blah") == nil
    Stash.set(stash, "blah", value)
    assert Stash.get(stash, "blah") == value
  end
end
