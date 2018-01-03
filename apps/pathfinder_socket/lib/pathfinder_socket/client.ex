defmodule PathfinderSocket.Client do
  @moduledoc """
  Socket client for AI player.
  """

  require Logger
  alias Phoenix.Channels.GenSocketClient
  alias Pathfinder.AI
  alias Pathfinder.Board
  alias Pathfinder.Stash

  @behaviour GenSocketClient
  @bot_id -2

  def start_link({registry, id}, stash, url, endpoint, opts \\ []) do
    name = {:via, Registry, {registry, id}}
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      {stash, url, id, endpoint},
      [],
      [{:name, name} | opts]
    )
  end

  def init({stash, url, id, endpoint}) do
    if state = Stash.get(stash, id) do
      connect(url, state, id, endpoint)
    else
      state = %{
        game_id: id,
        ai: AI.new(),
        board: Board.new(),
        game_state: nil,
        curr_ref: nil,
        curr_args: nil,
        stash: stash
      }
      Stash.set(stash, id, state)
      connect(url, state, id, endpoint)
    end
  end

  defp connect(url, state, id, endpoint) do
    token = Phoenix.Token.sign(endpoint, "bot", id)
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

  def handle_message("games:" <> game_id, event, payload, transport, state) do
    if game_id == Integer.to_string(state.game_id) do
      _handle_message(event, payload, transport, state)
    else
      {:ok, state}
    end
  end
  def handle_message(_topic, _event, _payload, _transport, state), do: {:ok, state}

  defp _handle_message("next", %{"state" => ["turn", @bot_id]}, transport, state) do
    args = {ai, _, move} = AI.move(state.ai, state.board)
    move = serialize_change(move)

    {:ok, ref} = GenSocketClient.push(
      transport,
      channel_name(state.game_id),
      "turn",
      %{"action" => move}
    )
    {:ok, %{state | ai: ai, curr_ref: ref, curr_args: args}}
  end
  defp _handle_message("next", %{"state" => ["win", _]}, _transport, state) do
    {:stop, :normal, state}
  end
  defp _handle_message(event, payload, _transport, state) do
    Logger.info("#{event}: #{inspect payload}")
    {:ok, state}
  end

  def handle_reply("games:" <> game_id, ref, payload, transport, state) do
    if game_id == Integer.to_string(state.game_id) do
      _handle_reply(ref, payload, transport, state)
    else
      {:ok, state}
    end
  end
  def handle_reply(_topic, _ref, _payload, _transport, state), do: {:ok, state}

  def _handle_reply(
    ref,
    %{"status" => status},
    _transport,
    %{curr_ref: curr_ref, curr_args: curr_args, board: board} = state
  ) when ref == curr_ref do
    if status == "ok" do
      {_, _, {fun, fun_args}} = curr_args
      ai = Kernel.apply(AI, :move_success, Tuple.to_list(curr_args))
      {:ok, board} = Kernel.apply(Board, fun, [board | fun_args])
      {:ok, %{state | ai: ai, board: board, curr_ref: nil, curr_args: nil}}
    else
      {:ok, %{state | curr_ref: nil, curr_args: nil}}
    end
  end
  def _handle_reply(_ref, payload, _transport, state) do
    Logger.info("reply: #{inspect payload}")
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
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def terminate(_reason, %{stash: stash, game_id: id} = state) do
    Stash.set(stash, id, state)
  end

  def convert_to_lists(params) do
    Enum.map(params, fn
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
      value -> value
    end)
  end

  def serialize_change({name, params}) do
    %{"name" => Atom.to_string(name), "params" => convert_to_lists(params)}
  end
end
