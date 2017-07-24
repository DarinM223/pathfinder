defmodule Pathfinder.Store.EtsTest do
  use ExUnit.Case

  alias Pathfinder.Store
  alias Pathfinder.Store.Ets

  test "get/set should work properly" do
    game = %{a: true, b: [1, 2, 3]}

    retrieved_game =
      Ets.new(:table)
      |> Store.set("abcdefg", game)
      |> Store.get("abcdefg")

    assert retrieved_game == game
  end

  test "get should return nil if there is no key" do
    assert Store.get(Ets.new(:table), "abcdefg") == nil
  end

  test "delete should delete key" do
    retrieved_game =
      Ets.new(:table)
      |> Store.set("abcdefg", %{a: true})
      |> Store.delete("abcdefg")
      |> Store.get("abcdefg")

    assert retrieved_game == nil
  end
end
