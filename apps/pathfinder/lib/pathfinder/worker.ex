defmodule Pathfinder.Worker do
  @moduledoc """
  A game worker that handles a single pathfinder game.
  """

  use GenServer

  alias Pathfinder.Game

  def start_link({registry, id}, store, opts \\ []) do
    name = {:via, Registry, {registry, id}}
    GenServer.start_link(__MODULE__, {store, id}, [{:name, name} | opts])
  end

  def init({store, id}) do
    if game = Pathfinder.Store.get(store, id) do
      {:ok, game}
    else
      {:ok, Game.new()}
    end
  end

  def handle_call(:state, _from, game), do: {:reply, game, game}

  def handle_call({:build, player, changes}, _from, game) do
    case Game.build(game, player, changes) do
      {:turn, player, game} ->
        {:reply, {:turn, player}, game}
      {:ok, game} ->
        {:reply, :ok, game}
      _ ->
        {:reply, :error, game}
    end
  end

  def handle_call({:turn, player, action}, _from, game) do
    case Game.turn(game, player, action) do
      {:win, player, game} ->
        {:reply, {:win, player}, game}
      {:turn, player, game} ->
        {:reply, {:turn, player}, game}
      {:error, player, game} ->
        {:reply, {:error, player}, game}
    end
  end
end
