defmodule PathfinderSocket do
  use Application

  @registry Application.get_env(:pathfinder_socket, :registry)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(PathfinderSocket.Supervisor, []),
      supervisor(Registry, [:unique, @registry]),
      worker(Pathfinder.Stash, [[name: PathfinderSocket.Stash]])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  def add(id, endpoint, stash \\ PathfinderSocket.Stash) do
    PathfinderSocket.Supervisor.start_child(
      PathfinderSocket.Supervisor,
      id,
      stash,
      socket_url(endpoint),
      endpoint
    )
  end

  def has_worker?(id, stash \\ PathfinderSocket.Stash) do
    not is_nil(Pathfinder.Stash.get(stash, id))
  end

  def socket_url(endpoint) do
    endpoint.url |> String.replace("http", "ws") |> Kernel.<>("/socket/websocket")
  end
end
