defmodule Pathfinder do
  @moduledoc """
  Documentation for Pathfinder.
  """

  use Application

  @registry Application.get_env(:pathfinder, :registry)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Pathfinder.Supervisor, []),
      supervisor(Registry, [:unique, @registry]),
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: __MODULE__])
  end

  @doc """
  Load a game worker with the game stored in
  the given store and with the given id.
  """
  def add(store, id) do
    Pathfinder.Supervisor.start_child(Pathfinder.Supervisor, store, id)
  end
end
