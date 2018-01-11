defmodule PathfinderWeb.DataTest do
  use PathfinderWeb.DataCase, async: true

  alias PathfinderWeb.Data

  setup do
    {:ok, user} = insert_user()

    {:ok, user: user}
  end

  test "create_user_game validates other_user_type and other_user_name exists", %{user: user} do
    assert {:error, _} = Data.create_user_game(user, %{
      shareid: "blah",
      accessed: true, winner: 2
    })
  end

  test "create_user_game validates other_user_name refers to a valid user when type is existing", %{user: user} do
    assert {:error, _} = Data.create_user_game(user, %{
      other_user_name: "blah",
      other_user_type: "existing"
    })
  end

  test "create_user_game validates other_user_type is a valid type", %{user: user} do
    {:ok, other} = insert_user(%{username: "foo"})
    assert {:error, _} = Data.create_user_game(user, %{
      other_user_name: other.username,
      other_user_type: "blah"
    })
  end

  test "create_user_game validates other_user_name refers to a different user" , %{user: user} do
    assert {:error, _} = Data.create_user_game(user, %{
      other_user_name: user.username,
      other_user_type: "existing"
    })
  end

  test "create_user_game properly creates new game with existing user", %{user: user} do
    {:ok, other} = insert_user(%{username: "foo"})
    {:ok, game} = Data.create_user_game(user, %{other_user_name: other.username, other_user_type: "existing"})

    assert game.other_user_id == other.id
    assert game.other_user_name == other.username
    assert game.shareid != nil
    assert game.accessed == false
    assert game.winner == nil
  end

  test "create_user_game properly creates new game with nonexisting user", %{user: user} do
    {:ok, game} = Data.create_user_game(user, %{other_user_name: "foo", other_user_type: "nonexisting"})

    assert game.other_user_id == -1
    assert game.other_user_name == "foo"
    assert game.shareid != nil
    assert game.accessed == false
    assert game.winner == nil
  end

  test "get_user_game! validates that user owns game", %{user: user} do
    {:ok, other} = insert_user(%{username: "foo"})
    {:ok, game} = insert_game(other)

    assert_raise Ecto.NoResultsError, fn ->
      Data.get_user_game!(user, game.id)
    end

    assert Data.get_user_game!(other, game.id).id == game.id
  end

  test "update_game only allows accessed and winner to be updated", %{user: user} do
    {:ok, game} = insert_game(user)

    {:ok, updated_game} = Data.update_game(game, %{
      other_user_id: 20,
      shareid: "foo",
      accessed: true,
      winner: -1,
      other_user_name: "hello",
      other_user_type: "blah"
    })

    game =
      game
      |> Map.merge(%{accessed: true, winner: -1})
      |> Map.delete(:updated_at)

    updated_game = Map.delete(updated_game, :updated_at)
    assert game == updated_game
  end

  test "update_game requires winner to be either other_user_id or user_id", %{user: user} do
    {:ok, game} = insert_game(user)
    assert {:error, _} = Data.update_game(game, %{winner: user.id + 1})
    assert {:ok, _} = Data.update_game(game, %{winner: -1})
    assert {:ok, _} = Data.update_game(game, %{winner: user.id})
  end

  test "list_user_created_games returns games user created and \
        list_user_participating_games returns games user is participating in", %{user: user} do
    {:ok, other} = insert_user(%{username: "foo"})

    {:ok, game1} = insert_game(user)
    {:ok, game2} = insert_game(user)
    {:ok, game3} = insert_game(other, %{other_user_name: user.username, other_user_type: "existing"})
    {:ok, game4} = insert_game(other, %{other_user_name: user.username, other_user_type: "existing"})

    created_games =
      user
      |> Data.list_user_created_games()
      |> sorted_ids()

    participating_games =
      user
      |> Data.list_user_participating_games()
      |> sorted_ids()

    assert created_games == sorted_ids([game1, game2])
    assert participating_games == sorted_ids([game3, game4])
  end

  test "list_user_created_games and list_user_participating_games ignores completed games", %{user: user} do
    {:ok, other} = insert_user(%{username: "foo"})

    {:ok, game1} = insert_game(user)
    {:ok, game2} = insert_game(other, %{other_user_name: user.username, other_user_type: "existing"})
    {:ok, game3} = insert_game(user)
    {:ok, game4} = insert_game(other, %{other_user_name: user.username, other_user_type: "existing"})

    {:ok, _} = Data.update_game(game3, %{winner: user.id})
    {:ok, _} = Data.update_game(game4, %{winner: user.id})

    created_games =
      user
      |> Data.list_user_created_games()
      |> sorted_ids()

    participating_games =
      user
      |> Data.list_user_participating_games()
      |> sorted_ids()

    assert created_games == [game1.id]
    assert participating_games == [game2.id]
  end

  test "list_user_created_games with second parameter true only shows completed games", %{user: user} do
    {:ok, _} = insert_game(user)
    {:ok, won_game} = insert_game(user)

    {:ok, _} = Data.update_game(won_game, %{winner: user.id})

    created_games =
      user
      |> Data.list_user_created_games(true)
      |> sorted_ids()

    assert created_games == [won_game.id]
  end

  test "list_recent_other_usernames returns 10 most recent other usernames", %{user: user} do
    other_usernames = Enum.map(1..11, fn num ->
      {:ok, other_user} = insert_user()
      winner = if rem(num, 2) == 0, do: other_user.id, else: nil

      {:ok, game} = insert_game(user, %{
        other_user_name: other_user.username,
        other_user_type: "existing"
      })
      {:ok, _} = Data.update_game(game, %{winner: winner})

      other_user.username
    end)

    [_ | rest] = other_usernames
    assert Data.list_recent_other_usernames(user) == Enum.reverse(rest)
  end

  # Converts a list of games into a sorted list of the games ids.
  defp sorted_ids(games) do
    games
    |> Stream.map(&(&1.id))
    |> Enum.sort()
  end
end
