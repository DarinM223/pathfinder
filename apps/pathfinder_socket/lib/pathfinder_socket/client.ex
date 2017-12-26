defmodule PathfinderSocket.Client do
  @moduledoc """
  Socket client for AI player.
  """

  require Logger
  alias Phoenix.Channels.GenSocketClient
  alias Pathfinder.AI
  alias Pathfinder.Board

  @behaviour GenSocketClient

  def start_link(url, game_id, endpoint) do
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      {url, game_id, endpoint}
    )
  end

  def init({url, game_id, endpoint}) do
    state = %{
      game_id: game_id,
      ai: AI.new(),
      board: Board.new(),
      game_state: nil
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
    Process.send(self(), :connect, [])
    {:ok, state}
  end

  def handle_joined(topic, payload, _transport, state) do
    Logger.info("joined the topic #{topic}: #{inspect payload}")
    Process.send(self(), :send_build_changes, [])
    if payload != nil do
      {:ok, %{state | game_state: Map.get(payload, "state")}}
    else
      {:ok, state}
    end
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

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.info("reply on topic #{topic}: #{inspect payload}")
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    Logger.info("connecting")
    {:connect, state}
  end
  def handle_info({:join, topic}, transport, _state) do
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
