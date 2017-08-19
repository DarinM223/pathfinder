defmodule PathfinderWeb.Data do
  alias Ecto.Multi
  alias PathfinderWeb.Repo
  alias PathfinderWeb.Accounts.User
  alias PathfinderWeb.Data.Game
  alias PathfinderWeb.Data.Change
  import Ecto.Query

  @list_users_limit 100
  @other_users_limit 10

  def list_user_created_games(%User{} = user) do
    Repo.all(
      from g in Ecto.assoc(user, :games),
        where: is_nil(g.winner),
        order_by: [desc: g.inserted_at],
        limit: @list_users_limit
    )
  end

  def list_user_participating_games(%User{} = user) do
    Repo.all(
      from g in Game,
        where: g.other_user_id == ^user.id and is_nil(g.winner),
        order_by: [desc: g.inserted_at],
        limit: @list_users_limit,
        preload: [:user]
    )
  end

  def list_recent_other_usernames(%User{} = user) do
    other_user_games =
      from g in Ecto.assoc(user, :games),
        distinct: g.other_user_name,
        order_by: [desc: g.inserted_at]

    Repo.all(
      from g in subquery(other_user_games),
        select: g.other_user_name,
        order_by: [desc: g.inserted_at],
        limit: @other_users_limit
    )
  end

  def get_shared_game!(shareid) do
    Repo.get_by!(Game, shareid: shareid)
  end

  def get_game!(id) do
    Repo.get!(Game, id)
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

  def change_game(%Game{} = game \\ %Game{}, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  def update_on_win(%Game{} = game \\ %Game{}, winner_id, change_attrs_list) do
    multi =
      Multi.new()
      |> Multi.update(:game, change_game(game, %{winner: winner_id}))
      |> Multi.insert_all(:changes, Change, change_attrs_list)

    Repo.transaction(multi)
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
