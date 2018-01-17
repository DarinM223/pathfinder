defmodule PathfinderWeb.AccountsTest do
  use PathfinderWeb.DataCase, async: true

  alias PathfinderWeb.Accounts

  test "create_user validates password and password_confirm matches" do
    assert {:error, _} =
             Accounts.create_user(%{
               username: "blah",
               password: "secret",
               password_confirm: "wrong"
             })
  end

  test "create_user validates password and password_confirm exists" do
    assert {:error, _} = Accounts.create_user(%{username: "blah"})
  end

  test "create_user validates username to exist" do
    assert {:error, _} = Accounts.create_user(%{password: "secret", password_confirm: "secret"})
  end

  test "create_user validates username is between 1 and 20 characters" do
    assert {:error, _} =
             Accounts.create_user(%{
               username: "",
               password: "secret",
               password_confirm: "secret"
             })

    assert {:error, _} =
             Accounts.create_user(%{
               username: "123456789012345678901",
               password: "secret",
               password_confirm: "secret"
             })
  end

  test "create_user validates password is between 6 and 100 characters" do
    long_pass = Base.encode16(:crypto.strong_rand_bytes(101))

    assert {:error, _} =
             Accounts.create_user(%{
               username: "blah",
               password: "abcde",
               password_confirm: "abcde"
             })

    assert {:error, _} =
             Accounts.create_user(%{
               username: "blah",
               password: long_pass,
               password_confirm: long_pass
             })
  end

  test "create_user creates user with hash" do
    {:ok, user} =
      Accounts.create_user(%{
        name: "bob",
        username: "blah",
        password: "secret",
        password_confirm: "secret"
      })

    assert user.name == "bob"
    assert user.username == "blah"
    assert Comeonin.Bcrypt.checkpw("secret", user.password_hash)
  end

  test "get_user_by_username returns user by username" do
    {:ok, user} =
      Accounts.create_user(%{
        name: "bob",
        username: "blah",
        password: "secret",
        password_confirm: "secret"
      })

    assert Accounts.get_user_by_username("blah").id == user.id
  end

  test "get_user_by_username returns nil is user not found" do
    assert Accounts.get_user_by_username("bob") == nil
  end
end
