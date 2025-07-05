defmodule Pathfinder.Supervisor do
  use Supervisor

  @registry Application.compile_env(:pathfinder, :registry)

  def start_link(opts \\ [name: Pathfinder.Supervisor]) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, id, stash, player1, player2) do
    game_id = {@registry, id}
    result = Supervisor.start_child(supervisor, [game_id, stash, {player1, player2}])
    with {:ok, _} <- result, do: {:ok, game_id}
  end

  def init(:ok) do
    children = [
      worker(Pathfinder.Worker, [])
    ]

    supervise(children, strategy: :simple_one_for_one, max_restarts: 100)
  end
end
