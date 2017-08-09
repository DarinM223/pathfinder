defmodule PathfinderWeb.Data do
  alias PathfinderWeb.Repo
  alias PathfinderWeb.Accounts.User
  alias PathfinderWeb.Data.Game
  import Ecto.Query

  def list_user_created_games(%User{} = user) do
    user
    |> Ecto.assoc(:games)
    |> Repo.all()
  end

  def list_user_participating_games(%User{} = user) do
    Repo.all(from g in Game, where: g.other_user_id == ^user.id)
  end

  def get_shared_game!(shareid) do
    Repo.get_by!(Game, shareid: shareid)
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
    |> Game.create_changeset(user.id, attrs)
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
