defmodule Pathfinder.Worker do
  @moduledoc """
  A game worker that handles a single pathfinder game.
  """

  use GenServer

  require Logger

  alias Pathfinder.Game
  alias Pathfinder.Stash

  def start_link({registry, id}, stash, opts \\ []) do
    name = {:via, Registry, {registry, id}}
    GenServer.start_link(__MODULE__, {stash, id}, [{:name, name} | opts])
  end

  def init({stash, id}) do
    if game = Stash.get(stash, id) do
      {:ok, {game, {id, stash}}}
    else
      {:ok, {Game.new(), {id, stash}}}
    end
  end

  def handle_call(:state, _from, {game, _} = state) do
    {:reply, game, state}
  end

  def handle_call({:build, player, changes}, _from, {game, info}) do
    case Game.build(game, player, changes) do
      {:turn, player, game} ->
        {:reply, {:turn, player}, {game, info}}
      {:ok, game} ->
        {:reply, :ok, {game, info}}
      _ ->
        {:reply, :error, {game, info}}
    end
  end

  def handle_call({:turn, player, action}, _from, {game, info}) do
    case Game.turn(game, player, action) do
      {:win, player, game} ->
        {:reply, {:win, player}, {game, info}}
      {:turn, player, game} ->
        {:reply, {:turn, player}, {game, info}}
      {:error, player, game} ->
        {:reply, {:error, player}, {game, info}}
    end
  end

  def terminate(_reason, {game, {id, stash}}) do
    Stash.set(stash, id, game)
  end
end
