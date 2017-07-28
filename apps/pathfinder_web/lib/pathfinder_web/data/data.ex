defmodule PathfinderWeb.Data do
  alias PathfinderWeb.Repo
  alias PathfinderWeb.Accounts.User
  alias PathfinderWeb.Data.Game

  def list_user_games(%User{} = user) do
    user
    |> Ecto.assoc(:games)
    |> Repo.all()
  end

  def get_user_game!(%User{} = user, id) do
    user
    |> Ecto.assoc(:games)
    |> Repo.get!(id)
  end

  def change_user_game(%User{} = user) do
    user
    |> Ecto.build_assoc(:games)
    |> Game.changeset(%{})
  end

  def change_game(%Game{} = game \\ %Game{}) do
    Game.changeset(game, %{})
  end

  def create_user_game(%User{} = user, attrs) do
    user
    |> Ecto.build_assoc(:games)
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end
end
