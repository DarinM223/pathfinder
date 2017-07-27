defmodule PathfinderWeb.Web.UserController do
  use PathfinderWeb.Web, :controller

  alias PathfinderWeb.Accounts
  alias PathfinderWeb.Web.Auth

  plug :authenticate_user when action in [:show]

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    render conn, "show.html", user: user
  end

  def new(conn, params) do
    changeset = Accounts.change_user(%Accounts.User{})

    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> Auth.login(user)
        |> put_flash(:info, "#{user.name} created")
        |> redirect(to: page_path(conn, :index))
      {:error, changeset} ->
        render conn, "new.html", changeset: changeset
    end
  end
end
