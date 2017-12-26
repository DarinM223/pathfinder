defmodule PathfinderSocket.Supervisor do
  use Application
  use Supervisor

  @socket_url "ws://localhost:4000/socket/websocket"

  def start(_type, _args) do
    PathfinderSocket.Supervisor.start_link([name: __MODULE__])
  end

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_child(supervisor, url \\ @socket_url, game_id, endpoint) do
    Supervisor.start_child(
      supervisor,
      [url, game_id, endpoint]
    )
  end

  def init(:ok) do
    children = [
      worker(PathfinderSocket.Client, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
