defmodule PathfinderWeb.AuthTest do
  use PathfinderWeb.Web.ConnCase

  alias PathfinderWeb.Web.Auth
  alias PathfinderWeb.Accounts.User
  alias PathfinderWeb.Repo

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(PathfinderWeb.Web.Router, :browser)
      |> get("/")

    {:ok, conn: conn}
  end

  test "authenticate_user halts when no current_user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, nil)
      |> Auth.authenticate_user([])

    assert conn.halted
  end

  test "authenticate_user continues when current_user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %User{})
      |> Auth.authenticate_user([])

    refute conn.halted
  end

  test "login puts the user in the session", %{conn: conn} do
    login_conn =
      conn
      |> Auth.login(%User{id: 123})
      |> send_resp(:ok, "")

    next_conn = get(login_conn, "/")
    assert get_session(next_conn, :user_id) == 123
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn =
      conn
      |> put_session(:user_id, 123)
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    assert get_session(next_conn, :user_id) == nil
  end

  test "call places user from session into assigns", %{conn: conn} do
    {:ok, user} = insert_user()

    conn =
      conn
      |> put_session(:user_id, user.id)
      |> Auth.call(Repo)

    assert conn.assigns.current_user.id == user.id
  end

  test "call with no session sets current_user assign to nil", %{conn: conn} do
    conn = Auth.call(conn, Repo)
    assert conn.assigns.current_user == nil
  end

  test "login with valid username and password", %{conn: conn} do
    {:ok, user} = insert_user(%{username: "me", password: "secret", password_confirm: "secret"})

    {:ok, conn} = Auth.login_with_password(conn, user.username, "secret", repo: Repo)
    assert conn.assigns.current_user.id == user.id
  end

  test "login with not found user", %{conn: conn} do
    assert {:error, :not_found, _} = Auth.login_with_password(
      conn,
      "me",
      "secret",
      repo: Repo
    )
  end

  test "login with password mismatch", %{conn: conn} do
    {:ok, _} = insert_user(%{username: "me", password: "secret", password_confirm: "secret"})

    assert {:error, :unauthorized, _} = Auth.login_with_password(
      conn,
      "me",
      "wrong",
      repo: Repo
    )
  end
end
