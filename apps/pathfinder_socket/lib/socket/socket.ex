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

  def channel_name(game_id), do: "games:#{game_id}"

  def handle_connected(transport, state) do
    Logger.info("connected")
    GenSocketClient.join(transport, channel_name(state.game_id))
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("disconnected: #{inspect reason}")
    Process.send_after(self(), :connect, :timer.seconds(1))
    {:ok, state}
  end

  def handle_joined(topic, payload, transport, state) do
    Logger.info("joined the topic #{topic}: #{inspect payload}")
    Process.send_after(self(), :send_build_changes, :timer.seconds(1))
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
    Logger.info("message on topic #{topic}: #{event} #{inspect payload}")
    {:ok, state}
  end

  def handle_reply("ping", _ref, %{"status" => "ok"} = payload, _transport, state) do
    Logger.info("server pong ##{payload["response"]["ping_ref"]}")
    {:ok, state}
  end

  # TODO(DarinM223): add reply to build and move messages

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.info("reply on topic #{topic}: #{inspect payload}")
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
  def handle_info(:send_build_changes, transport, state) do
    Logger.info("sending build changes")
    changes = Board.generate_changes() |> Enum.map(&serialize_change/1)
    GenSocketClient.push(transport, channel_name(state.game_id), "build", %{"changes" => changes})
    {:ok, state}
  end
  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, state}
  end

  defp convert_to_lists(params) do
    Enum.map(params, fn
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
      value -> value
    end)
  end

  defp serialize_change({name, params}) do
    %{"name" => Atom.to_string(name), "params" => convert_to_lists(params)}
  end
end
