defmodule Pathfinder.Supervisor do
  use DynamicSupervisor

  @registry Application.compile_env(:pathfinder, :registry)

  def start_link(opts \\ [name: Pathfinder.Supervisor]) do
    DynamicSupervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(id, stash, player1, player2) do
    game_id = {@registry, id}

    spec = Pathfinder.Worker.child_spec([game_id, stash, {player1, player2}])
    result = DynamicSupervisor.start_child(__MODULE__, spec)

    with {:ok, _} <- result, do: {:ok, game_id}
  end

  def init(:ok) do
    DynamicSupervisor.init(max_restarts: 100, strategy: :one_for_one)
  end
end
