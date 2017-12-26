defmodule PathfinderWeb.Web.SocketChannelTest do
  use PathfinderWeb.Web.ChannelCase
  import PathfinderWeb.TestHelpers

  alias PathfinderWeb.Web.UserSocket
  alias PathfinderSocket.Supervisor

  @build_changes [
    %{
      "name" => "set_wall",
      "params" => [3, true]
    },
    %{
      "name" => "place_goal",
      "params" => [[1, 1]]
    }
  ]
  @socket_url "ws://localhost:4001/socket/websocket"

  setup do
    {:ok, user} = insert_user(%{username: "bob"})
    {:ok, game} = insert_game(user, %{other_user_name: "dave", other_user_type: "bot"})

    user_token = Phoenix.Token.sign(@endpoint, "user socket", user.id)
    {:ok, socket} = connect(UserSocket, %{"token" => user_token})
    {:ok, _} = Supervisor.start_child(Supervisor, @socket_url, game.id, @endpoint)

    {:ok, game: game, user_socket: socket}
  end

  test "receives broadcast when user finishes building", %{game: game, user_socket: socket} do
    {:ok, _, socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
    ref = push socket, "build", %{"changes" => @build_changes}
    assert_reply ref, :ok, %{}

    assert_broadcast "next", %{changes: [], state: _}
  end
end
