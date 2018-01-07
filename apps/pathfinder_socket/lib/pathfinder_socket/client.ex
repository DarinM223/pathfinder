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

  def start_link({registry, id}, stash, url, endpoint, opts \\ []) when is_binary(id) do
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
    Process.flag(:trap_exit, true)
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
    Logger.info("join error from the topic #{topic}: #{inspect payload}")
    {:stop, :normal, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic}: #{inspect payload}")
    Process.send_after(self(), {:join, topic}, :timer.seconds(1))
    {:ok, state}
  end

  def handle_message("games:" <> id, "next", %{"state" => ["turn", @bot_id]}, transport, %{game_id: game_id} = state)
      when game_id == id do
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
  def handle_message("games:" <> id, "next", %{"state" => ["win", _]}, _t, %{game_id: game_id} = state)
      when game_id == id do
    {:stop, :normal, state}
  end
  def handle_message(topic, event, payload, _transport, state) do
    Logger.info("Topic #{topic} #{event}: #{inspect payload}")
    {:ok, state}
  end

  def handle_reply("games:" <> id, ref, %{"status" => "ok"}, _t, %{curr_ref: curr_ref, game_id: game_id} = state)
      when ref == curr_ref and game_id == id do
    {_, _, {fun, fun_args}} = state.curr_args
    ai = Kernel.apply(AI, :move_success, Tuple.to_list(state.curr_args))
    {:ok, board} = Kernel.apply(Board, fun, [state.board | fun_args])
    {:ok, %{state | ai: ai, board: board, curr_ref: nil, curr_args: nil}}
  end
  def handle_reply("games:" <> id, ref, _p, _t, %{curr_ref: curr_ref, game_id: game_id} = state)
      when ref == curr_ref and game_id == id do
    {:ok, %{state | curr_ref: nil, curr_args: nil}}
  end
  def handle_reply(_topic, _ref, payload, _transport, state) do
    Logger.info("reply: #{inspect payload}")
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

    {:ok, state}
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
