defmodule PathfinderWeb.Web.GameController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def index(conn, _, user) do
    created_games = Data.list_user_created_games(user)
    participating_games = Data.list_user_participating_games(user)

    render conn, "index.html",
      created_games: created_games,
      participating_games: participating_games
  end

  def new(conn, _params, user) do
    changeset = Data.change_game()
    recent_other_usernames = Data.list_recent_other_usernames(user)

    render conn, "new.html",
      changeset: changeset,
      recent_other_usernames: recent_other_usernames
  end

  def create(conn, %{"game" => game_params}, user) do
    case Data.create_user_game(user, game_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Game created successfully")
        |> redirect(to: game_path(conn, :index))
      {:error, changeset} ->
        recent_other_usernames = Data.list_recent_other_usernames(user)
        render conn, "new.html",
          changeset: changeset,
          recent_other_usernames: recent_other_usernames
    end
  end

  def show(conn, %{"id" => id}, user) do
    game = Data.get_user_game!(user, id)

    # Start up game socket client if it isn't started for a bot game.
    if game.other_user_id == -2 and not PathfinderSocket.has_worker?(id) do
      {:ok, _} = PathfinderSocket.add(id, PathfinderWeb.Web.Endpoint)
    end

    render conn, "show.html", game: game
  end

  def delete(conn, %{"id" => id}, user) do
    game = Data.get_game!(id)
    if game.user_id == user.id or game.other_user_id == user.id do
      {:ok, _} = Data.delete_game(game)
      conn
      |> put_flash(:info, "Game deleted successfully")
      |> redirect(to: game_path(conn, :index))
    else
      conn
      |> put_flash(:error, "Invalid game id")
      |> redirect(to: game_path(conn, :index))
    end
  end

  def finish(conn, %{"id" => id}, user) do
    game = Data.get_game!(id)
    result =
      cond do
        user.id == game.user_id ->
          Data.update_game(game, %{winner: game.other_user_id})
        user.id == game.other_user_id ->
          Data.update_game(game, %{winner: game.user_id})
        true ->
          :error
      end

    with {:ok, _} <- result do
      conn
      |> put_flash(:info, "Game forfeited successfully")
      |> redirect(to: game_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid game id")
        |> redirect(to: game_path(conn, :index))
    end
  end

  @doc """
  Default plug called by Phoenix framework that
  dispatches to the proper action.

  This is overwritten because we want to include the user as a
  parameter to the route functions.
  """
  def action(conn, _) do
    apply(__MODULE__, action_name(conn),
          [conn, conn.params, conn.assigns.current_user])
  end
end
