defmodule Pathfinder.Supervisor do
  use Supervisor

  @registry Application.get_env(:pathfinder, :registry)

  def start_link(opts \\ [name: Pathfinder.Supervisor]) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, store, id) do
    with {:ok, _} <- Supervisor.start_child(supervisor, [@registry, store, id]),
         do: {:ok, id}
  end

  def init(:ok) do
    children = [
      worker(Pathfinder.Worker, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
