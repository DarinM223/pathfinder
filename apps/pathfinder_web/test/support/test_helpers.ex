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
    changes = Map.merge(%{
      other_user_name: Base.encode16(:crypto.strong_rand_bytes(8)),
      other_user_type: "nonexisting"
    }, attrs)
    Data.create_user_game(user, changes)
  end
end
