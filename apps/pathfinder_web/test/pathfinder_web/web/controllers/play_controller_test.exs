defmodule PathfinderWeb.Web.PlayControllerTest do
  use PathfinderWeb.Web.ConnCase

  test "shows token only once for unauthorized player", %{conn: conn} do
    {:ok, user} = insert_user(%{username: "bob"})
    {:ok, game} = insert_game(user, %{other_user_name: "dave"})

    next_conn = get(conn, play_path(conn, :show, game.shareid))
    assert String.contains?(next_conn.resp_body, "window.unauthorizedUserToken")

    next_conn = get(conn, play_path(conn, :show, game.shareid))
    refute String.contains?(next_conn.resp_body, "window.unauthorizedUserToken")
  end

  test "doesn't show token for logged in player", %{conn: conn} do
    {:ok, user} = insert_user(%{username: "bob"})
    {:ok, game} = insert_game(user, %{other_user_name: "dave"})

    conn = assign(conn, :current_user, user)
    conn = get(conn, play_path(conn, :show, game.shareid))

    refute String.contains?(conn.resp_body, "window.unauthorizedUserToken")
  end

  test "doesn't show token for unauthorized player if other user has an account", %{conn: conn} do
    {:ok, user} = insert_user(%{username: "bob"})
    {:ok, _} = insert_user(%{username: "dave"})
    {:ok, game} = insert_game(user, %{other_user_name: "dave", other_user_type: "existing"})

    conn = get(conn, play_path(conn, :show, game.shareid))

    refute String.contains?(conn.resp_body, "window.unauthorizedUserToken")
  end
end
