defmodule PathfinderWeb.Accounts do
  alias PathfinderWeb.Repo
  alias PathfinderWeb.Accounts.User

  def get_user(id, repo \\ Repo) do
    repo.get(User, id)
  end

  def get_user_by_username(username, repo \\ Repo) do
    repo.get_by(User, username: username)
  end

  def create_user(attrs \\ %{}, repo \\ Repo) do
    %User{}
    |> User.registration_changeset(attrs)
    |> repo.insert()
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
