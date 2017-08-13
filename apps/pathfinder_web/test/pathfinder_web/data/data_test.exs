defmodule PathfinderWeb.DataTest do
  use PathfinderWeb.DataCase, async: true

  alias PathfinderWeb.Data
  alias PathfinderWeb.Accounts

  setup do
    {:ok, user} = insert_user()

    {:ok, user: user}
  end

  test "create_user_game validates other_user_type and other_user_name exists", %{user: user} do
    assert {:error, _} =
      Data.create_user_game(user, %{shareid: "blah", accessed: true, winner: 2})
  end

  test "create_user_game validates other_user_name refers to a valid user when type is existing", %{user: user} do
    assert {:error, _} =
      Data.create_user_game(user, %{other_user_name: "blah", other_user_type: "existing"})
  end

  test "create_user_game validates other_user_type is a valid type", %{user: user} do
    {:ok, other} = insert_user(%{username: "foo"})
    assert {:error, _} =
      Data.create_user_game(user, %{other_user_name: other.username, other_user_type: "blah"})
  end

  test "create_user_game validates other_user_name refers to a different user" , %{user: user} do
    assert {:error, _} =
      Data.create_user_game(user, %{other_user_name: user.username, other_user_type: "existing"})
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
end
