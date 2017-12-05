defmodule Pathfinder.Socket.Client do
  @moduledoc """
  Socket client for AI player.
  """

  require Logger
  alias Phoenix.Channels.GenSocketClient
  alias Pathfinder.AI
  alias Pathfinder.Board

  @behaviour GenSocketClient
  @socket_url "ws://localhost:4000/socket/websocket"

  def start_link(url \\ @socket_url, endpoint, game_id) do
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      {url, endpoint, game_id}
    )
  end

  def init({url, endpoint, game_id}) do
    state = %{
      game_id: game_id,
      ai: AI.new(),
      board: Board.new()
    }
    token = Phoenix.Token.sign(endpoint, "bot", game_id)
    {:connect, url, [token: token], state}
  end

  def handle_connected(transport, %{game_id: game_id} = state) do
    Logger.info("connected")
    GenSocketClient.join(transport, "games:#{game_id}")
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("disconnected: #{inspect reason}")
    Process.send_after(self(), :connect, :timer.seconds(1))
    {:ok, state}
  end

  def handle_joined(topic, payload, transport, state) do
    Logger.info("joined the topic #{topic}: #{inspect payload}")

    # TODO(DarinM223): generate board and send build board changes
    # TODO(DarinM223): convert tuples in arguments to lists
    changes =
      Board.generate_changes()
      # |> Enum.map(fn {name, params} -> %{"name" => name, "params" => convert_to_lists(params)} end)

    IO.puts("Changes: #{inspect changes}")
    GenSocketClient.push(transport, "build", "build", %{"changes" => changes})
    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("join error from the topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    Process.send_after(self(), {:join, topic}, :timer.seconds(1))
    {:ok, state}
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("message on topic #{topic}: #{event} #{inspect payload}")
    {:ok, state}
  end

  def handle_reply("ping", _ref, %{"status" => "ok"} = payload, _transport, state) do
    Logger.info("server pong ##{payload["response"]["ping_ref"]}")
    {:ok, state}
  end

  # TODO(DarinM223): add reply to build and move messages

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    Logger.info("connecting")
    {:connect, state}
  end
  def handle_info({:join, topic}, transport, state) do
    Logger.info("joining the topic #{topic}")
    case GenSocketClient.join(transport, topic) do
      {:error, reason} ->
        Logger.error("error joining the topic #{topic}: #{inspect reason}")
        Process.send_after(self(), {:join, topic}, :timer.seconds(1))
      {:ok, _ref} -> :ok
    end
  end
  # TODO(DarinM223): delete this later
  def handle_info(:ping_server, transport, state) do
    Logger.info("sending ping ##{state.ping_ref}")
    GenSocketClient.push(transport, "ping", "ping", %{ping_ref: state.ping_ref})
    {:ok, %{state | ping_ref: state.ping_ref + 1}}
  end
  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, state}
  end
end
