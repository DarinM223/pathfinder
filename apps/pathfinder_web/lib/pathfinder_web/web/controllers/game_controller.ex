defmodule PathfinderWeb.Web.GameController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Data

  def index(conn, _, user) do
    games = Data.list_user_games(user)

    render conn, "index.html", games: games
  end

  def create(conn, _params, user) do
    case Data.create_user_game(user, %{}) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Game created successfully")
        |> redirect(to: game_path(conn, :index))
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end

  def show(conn, %{"id" => id}, user) do
    game = Data.get_user_game!(user, id)

    render conn, "show.html", game: game
  end

  def delete(conn, %{"id" => id}, user) do
    game = Data.get_user_game!(user, id)
    {:ok, _} = Data.delete_game(game)

    conn
    |> put_flash(:info, "Video deleted successfully")
    |> redirect(to: game_path(conn, :index))
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
