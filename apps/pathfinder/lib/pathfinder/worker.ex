defmodule Pathfinder.Worker do
  @moduledoc """
  A game worker that handles a single pathfinder game.
  """

  use GenServer

  alias Pathfinder.Game

  def start_link(registry, store, id, opts \\ []) do
    name = {:via, Registry, {registry, id}}
    GenServer.start_link(__MODULE__, {store, id}, [{:name, name} | opts])
  end

  def state(registry, id) do
    GenServer.call(name(registry, id), :state)
  end

  def name(registry, id) do
    {:via, Registry, {registry, id}}
  end

  def init({store, id}) do
    if game = Pathfinder.Store.get(store, id) do
      {:ok, game}
    else
      {:ok, Game.new()}
    end
  end

  # Debugging call to retrieve the state
  def handle_call(:state, _from, game), do: {:reply, game, game}

  def handle_call({:build, player, changes}, _from, game) do
    with {:ok, game} <- Game.build(game, player, changes) do
      {:reply, :ok, game}
    else
      _ -> {:reply, :error, game}
    end
  end

  def handle_call({:turn, player, action}, _from, game) do
    {:reply, :ok, Game.turn(game, player, action)}
  end
end
