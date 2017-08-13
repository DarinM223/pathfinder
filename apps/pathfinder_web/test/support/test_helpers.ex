defmodule PathfinderWeb.TestHelpers do
  alias PathfinderWeb.Accounts
  alias PathfinderWeb.Data

  def insert_user(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "Some User",
      username: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      password: "supersecret",
      password_confirm: "supersecret"
    }, attrs)

    Accounts.create_user(changes)
  end

  def insert_game(user, attrs \\ %{}) do
    Data.create_user_game(user, attrs)
  end
end
