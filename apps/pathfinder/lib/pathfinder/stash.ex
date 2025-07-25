defmodule Pathfinder.Stash do
  use Agent

  def start_link(opts \\ [name: Pathfinder.Stash]) do
    Agent.start_link(fn -> %{} end, opts)
  end

  def get(stash, id) do
    Agent.get(stash, &Map.get(&1, inspect(id)))
  end

  def set(stash, id, value) do
    Agent.update(stash, &Map.put(&1, inspect(id), value))
  end
end
