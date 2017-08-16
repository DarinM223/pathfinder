defmodule PathfinderWeb.Web.GameChannelTest do
  use PathfinderWeb.Web.ChannelCase
  import PathfinderWeb.TestHelpers

  alias PathfinderWeb.Web.UserSocket

  setup config do
    {:ok, user} = insert_user(%{username: "bob"})
    {:ok, game} = insert_game(user, %{other_user_name: "dave"})

    token =
      if id = config[:sign_token_as] do
        Phoenix.Token.sign(@endpoint, "user socket", id)
      else
        Phoenix.Token.sign(@endpoint, "user socket", user.id)
      end
    {:ok, socket} = connect(UserSocket, %{"token" => token})

    {:ok, user: user, game: game, socket: socket}
  end

  @tag sign_token_as: -100
  test "join fails if user is not a player in the game", %{game: game, socket: socket} do
    assert subscribe_and_join(socket, "games:#{game.id}", %{}) == {:error, "User is not a player in this game"}
  end

  test "sends nothing back on first join and sends player state on the next joins", %{user: user, game: game, socket: socket} do
    {:ok, nil, next_socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
    assert next_socket.assigns.game_id != nil

    {:ok, state, _} = subscribe_and_join(socket, "games:#{game.id}", %{})
    assert state.id == user.id
  end

  test "build broadcasts next turn to all players when both players finish building", %{game: game, socket: socket} do
    token = Phoenix.Token.sign(@endpoint, "non-logged-in-user socket", "blah")
    {:ok, other_socket} = connect(UserSocket, %{"token" => token})

    {:ok, _, socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
    {:ok, _, other_socket} = subscribe_and_join(other_socket, "games:#{game.id}", %{})

    changes = [
      %{
        "name" => "set_wall",
        "params" => [[2, 2], [2, 3], true]
      },
      %{
        "name" => "place_goal",
        "params" => [[3, 5]]
      }
    ]

    ref = push socket, "build", %{"changes" => changes}
    assert_reply ref, :ok, %{}

    ref = push other_socket, "build", %{"changes" => changes}
    assert_broadcast "next", %{changes: [], state: _}
    assert_reply ref, :ok, %{}
  end

  test "turn broadcasts next turn to all players" do
    # TODO(DarinM223): implement this
  end

  test "turn broadcasts next turn to all players and updates winner when game is won" do
    # TODO(DarinM223): implement this
  end

  test "turn broadcasts next turn to all players on error" do
    # TODO(DarinM223): implement this
  end
end
