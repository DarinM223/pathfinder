defmodule PathfinderWeb.Web.GameChannelTest do
  use PathfinderWeb.Web.ChannelCase
  import PathfinderWeb.TestHelpers

  alias PathfinderWeb.Web.UserSocket
  alias PathfinderWeb.Data

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

    if changes = config[:builds_boards_with] do
      token = Phoenix.Token.sign(@endpoint, "non-logged-in-user socket", "blah")
      {:ok, other_socket} = connect(UserSocket, %{"token" => token})

      {:ok, _, socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
      {:ok, _, other_socket} = subscribe_and_join(other_socket, "games:#{game.id}", %{})

      push(socket, "build", %{"changes" => changes})
      push(other_socket, "build", %{"changes" => changes})

      assert_broadcast("next", %{changes: [], state: [:turn, player]})
      {:ok, user: user, game: game, socket: socket, other_socket: other_socket, player: player}
    else
      {:ok, user: user, game: game, socket: socket}
    end
  end

  @tag sign_token_as: -100
  test "join fails if user is not a player in the game", %{game: game, socket: socket} do
    assert subscribe_and_join(socket, "games:#{game.id}", %{}) ==
             {:error, "User is not a player in this game"}
  end

  test "sends nothing back on first join and sends player state on the next joins", %{
    user: user,
    game: game,
    socket: socket
  } do
    {:ok, nil, next_socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
    assert next_socket.assigns.worker_id != nil

    {:ok, state, _} = subscribe_and_join(socket, "games:#{game.id}", %{})
    assert state.id == user.id
  end

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
  @action %{
    "name" => "place_player",
    "params" => [2]
  }
  @win_action %{
    "name" => "place_player",
    "params" => [1]
  }
  @blocked_action %{
    "name" => "place_player",
    "params" => [3]
  }

  test "build broadcasts next turn to all players when both players finish building", %{
    game: game,
    socket: socket
  } do
    token = Phoenix.Token.sign(@endpoint, "non-logged-in-user socket", "blah")
    {:ok, other_socket} = connect(UserSocket, %{"token" => token})

    {:ok, _, socket} = subscribe_and_join(socket, "games:#{game.id}", %{})
    {:ok, _, other_socket} = subscribe_and_join(other_socket, "games:#{game.id}", %{})

    ref = push(socket, "build", %{"changes" => @build_changes})
    assert_reply(ref, :ok, %{})

    ref = push(other_socket, "build", %{"changes" => @build_changes})
    assert_broadcast("next", %{changes: [], state: _})
    assert_reply(ref, :ok, %{})
  end

  @tag builds_boards_with: @build_changes
  test "turn broadcasts next turn to all players", %{
    user: user,
    socket: socket,
    other_socket: other_socket,
    player: player
  } do
    user_id = user.id

    if player == -1 do
      ref = push(other_socket, "turn", %{"action" => @action})
      assert_broadcast("next", %{changes: [@action], state: [:turn, ^user_id]})
      assert_reply(ref, :ok, %{})
    else
      ref = push(socket, "turn", %{"action" => @action})
      assert_broadcast("next", %{changes: [@action], state: [:turn, -1]})
      assert_reply(ref, :ok, %{})
    end
  end

  @tag builds_boards_with: @build_changes
  test "turn broadcasts next turn to all players and updates winner when game is won", %{
    user: user,
    game: game,
    socket: socket,
    other_socket: other_socket,
    player: player
  } do
    user_id = user.id

    if player == -1 do
      ref = push(other_socket, "turn", %{"action" => @win_action})
      assert_broadcast("next", %{changes: [@win_action], state: [:win, -1]})
      assert_reply(ref, :ok, %{})
      assert Data.get_user_game!(user, game.id).winner == -1
    else
      ref = push(socket, "turn", %{"action" => @win_action})
      assert_broadcast("next", %{changes: [@win_action], state: [:win, ^user_id]})
      assert_reply(ref, :ok, %{})
      assert Data.get_user_game!(user, game.id).winner == user_id
    end
  end

  @tag builds_boards_with: @build_changes
  test "turn broadcasts next turn to all players on error", %{
    user: user,
    socket: socket,
    other_socket: other_socket,
    player: player
  } do
    user_id = user.id
    highlight_action = %{name: "highlight_position", params: [[3, 1]]}

    if player == -1 do
      ref = push(other_socket, "turn", %{"action" => @blocked_action})
      assert_broadcast("next", %{changes: [^highlight_action], state: [:turn, ^user_id]})
      assert_reply(ref, :error, %{})
    else
      ref = push(socket, "turn", %{"action" => @blocked_action})
      assert_broadcast("next", %{changes: [^highlight_action], state: [:turn, -1]})
      assert_reply(ref, :error, %{})
    end
  end
end
