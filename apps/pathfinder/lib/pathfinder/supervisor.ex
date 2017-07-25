defmodule Pathfinder.Supervisor do
  use Supervisor

  @registry Application.get_env(:pathfinder, :registry)

  def start_link(opts \\ [name: Pathfinder.Supervisor]) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, store, id) do
    game_id = {@registry, id}
    with {:ok, _} <- Supervisor.start_child(supervisor, [game_id, store]) do
      {:ok, game_id}
    end
  end

  def init(:ok) do
    children = [
      worker(Pathfinder.Worker, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
