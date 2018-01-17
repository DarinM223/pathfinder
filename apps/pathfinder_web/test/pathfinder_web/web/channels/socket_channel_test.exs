defmodule PathfinderWeb.Web.SocketChannelTest do
  use PathfinderWeb.Web.ChannelCase
  import PathfinderWeb.TestHelpers

  alias PathfinderWeb.Web.UserSocket
  alias PathfinderSocket.Client
  alias Pathfinder.AI
  alias Pathfinder.Board
  alias Pathfinder.Stash

  @socket_url "ws://localhost:4001/socket/websocket"

  setup context do
    {:ok, user} = insert_user(%{username: "bob"})
    {:ok, game} = insert_game(user, %{other_user_name: "dave", other_user_type: "bot"})

    user_token = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    {:ok, socket} = connect(UserSocket, %{"token" => user_token})

    registry = :"#{context.test}_registry"
    id = {registry, Integer.to_string(game.id)}
    {:ok, _} = Registry.start_link(:unique, registry)
    {:ok, stash} = Stash.start_link(name: :"#{context.test}_stash")

    assert is_nil(Stash.get(stash, Integer.to_string(game.id)))
    {:ok, _} = Client.start_link(id, stash, @socket_url, @endpoint)
    assert not is_nil(Stash.get(stash, Integer.to_string(game.id)))

    {:ok, game: game, user_socket: socket}
  end

  test "properly plays a game with the bot", %{game: game, user_socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
    build_changes = Board.generate_changes() |> Enum.map(&Client.serialize_change/1)
    ref = push(socket, "build", %{"changes" => build_changes})
    assert_reply(ref, :ok, %{})

    assert play_game(socket, game.user_id, AI.new(), Board.new())

    :timer.sleep(200)
  end

  # Plays the game with the bot until someone wins.
  defp play_game(socket, test_player_id, ai, board) do
    assert_broadcast("next", %{changes: _, state: state})

    case state do
      [:turn, ^test_player_id] ->
        args = {_, _, {fun, fun_args}} = AI.move(ai, board)
        move = Client.serialize_change({fun, fun_args})
        ref = push(socket, "turn", %{"action" => move})
        assert_reply(ref, reply, %{})

        {ai, board} =
          case reply do
            :ok ->
              {
                Kernel.apply(AI, :move_success, Tuple.to_list(args)),
                Kernel.apply(Board, fun, [board | fun_args]) |> elem(1)
              }

            _ ->
              {elem(args, 0), board}
          end

        play_game(socket, test_player_id, ai, board)

      [:turn, _] ->
        play_game(socket, test_player_id, ai, board)

      [:win, _] ->
        true
    end
  end
end
