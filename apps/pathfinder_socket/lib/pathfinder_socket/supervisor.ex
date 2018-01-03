defmodule PathfinderSocket.Supervisor do
  use Supervisor

  @registry Application.get_env(:pathfinder_socket, :registry)
  @socket_url "ws://localhost:4000/socket/websocket"

  def start_link(opts \\ [name: PathfinderSocket.Supervisor]) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, id, stash, url, endpoint) do
    socket_id = {@registry, id}
    result = Supervisor.start_child(
      supervisor,
      [socket_id, stash, url, endpoint]
    )
    with {:ok, _} <- result, do: {:ok, socket_id}
  end

  def init(:ok) do
    children = [
      worker(PathfinderSocket.Client, [])
    ]

    supervise(children, strategy: :simple_one_for_one, restart: :temporary)
  end
end
