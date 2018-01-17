defmodule Pathfinder do
  @moduledoc """
  Documentation for Pathfinder.
  """

  use Application

  @registry Application.get_env(:pathfinder, :registry)
  @max_timeout 1_000
  @retry_time 200

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Pathfinder.Supervisor, []),
      supervisor(Registry, [:unique, @registry]),
      worker(Pathfinder.Stash, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  @doc """
  Load a game worker with the given id.
  """
  def add(id, player1, player2, stash \\ Pathfinder.Stash) do
    Pathfinder.Supervisor.start_child(
      Pathfinder.Supervisor,
      id,
      stash,
      player1,
      player2
    )
  end

  @doc """
  Returns the id of the worker if the game is already running, otherwise returns nil.
  """
  def worker_id(id, registry \\ @registry, stash \\ Pathfinder.Stash) do
    if Pathfinder.Stash.get(stash, id), do: {registry, id}, else: nil
  end

  @doc """
  Returns the game state in the worker.

  Mostly used for debugging worker errors.
  """
  def state(id) do
    retry_call(&GenServer.call/2, [name(id), :state])
  end

  @doc """
  Sends a player's grid building changes to the game.
  """
  def build(id, player, changes) do
    retry_call(&GenServer.call/2, [name(id), {:build, player, changes}])
  end

  @doc """
  Sends a player's turn to the game.
  """
  def turn(id, player, action) do
    retry_call(&GenServer.call/2, [name(id), {:turn, player, action}])
  end

  defp name({_registry, _id} = id) do
    {:via, Registry, id}
  end

  defp retry_call(f, args, total_time \\ 0) do
    try do
      Kernel.apply(f, args)
    catch
      :exit, _ ->
        if total_time >= @max_timeout do
          {:error, :timeout}
        else
          :timer.sleep(@retry_time)
          retry_call(f, args, total_time + @retry_time)
        end
    end
  end
end
