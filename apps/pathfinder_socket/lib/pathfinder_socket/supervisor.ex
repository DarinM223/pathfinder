defmodule PathfinderSocket.Supervisor do
  use DynamicSupervisor

  @registry Application.compile_env(:pathfinder_socket, :registry)

  def start_link(opts \\ [name: PathfinderSocket.Supervisor]) do
    DynamicSupervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, id, stash, url, endpoint) do
    socket_id = {@registry, id}

    spec = %{
      id: PathfinderSocket.Client,
      start: {PathfinderSocket.Client, :start_link, [socket_id, stash, url, endpoint]}
    }

    result = DynamicSupervisor.start_child(supervisor, spec)
    with {:ok, _} <- result, do: {:ok, socket_id}
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one, restart: :temporary)
  end
end
