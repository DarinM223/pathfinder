defmodule PathfinderWeb.Web.GameControllerTest do
  use PathfinderWeb.Web.ConnCase

  alias PathfinderWeb.Data

  setup %{conn: conn} = config do
    if username = config[:login_as] do
      {:ok, user} = insert_user(%{username: username})
      conn = assign(conn, :current_user, user)
      {:ok, conn: conn, user: user}
    else
      :ok
    end
  end

  test "requires user authentication on all actions", %{conn: conn} do
    Enum.each([
      get(conn, game_path(conn, :new)),
      get(conn, game_path(conn, :index)),
      get(conn, game_path(conn, :show, "123")),
      post(conn, game_path(conn, :create, %{})),
      delete(conn, game_path(conn, :delete, "123"))
    ], fn conn ->
      assert html_response(conn, 302)
      assert conn.halted
    end)
  end

  @tag login_as: "bob"
  test ":index lists created and participating games by username", %{conn: conn, user: user} do
    {:ok, other} = insert_user(%{username: "dave"})

    {:ok, _} = insert_game(user, %{other_user_name: "dave", other_user_type: "existing"})
    {:ok, _} = insert_game(user, %{other_user_name: "dave", other_user_type: "existing"})
    {:ok, _} = insert_game(other, %{other_user_name: "bob", other_user_type: "existing"})
    {:ok, _} = insert_game(other, %{other_user_name: "bob", other_user_type: "existing"})

    conn = get conn, game_path(conn, :index)
    assert html_response(conn, 200) =~ "Your created games:"

    assert String.contains?(conn.resp_body, "dave")
    assert String.contains?(conn.resp_body, "dave (2)")
    assert length(Regex.scan(~r/dave \(2\)/, conn.resp_body)) == 2
    assert length(Regex.scan(~r/dave/, conn.resp_body)) == 4
  end

  @tag login_as: "bob"
  test ":index doesn't show won games", %{conn: conn, user: user} do
    {:ok, _} = insert_game(user, %{other_user_name: "joe"})
    {:ok, game} = insert_game(user, %{other_user_name: "sarah"})

    {:ok, _} = Data.update_game(game, %{winner: -1})

    conn = get conn, game_path(conn, :index)

    assert html_response(conn, 200)
    assert String.contains?(conn.resp_body, "joe")
    refute String.contains?(conn.resp_body, "sarah")
  end

  @tag login_as: "bob"
  test ":create successfully creates game with existing user and redirects", %{conn: conn, user: user} do
    {:ok, other} = insert_user(%{username: "dave"})

    attrs = %{other_user_name: other.username, other_user_type: "existing"}

    conn = post conn, game_path(conn, :create, game: attrs)
    [game] = Data.list_user_created_games(user)

    assert redirected_to(conn) == game_path(conn, :index)
    assert game.user_id == user.id and game.other_user_name == other.username
  end

  @tag login_as: "bob"
  test ":create successfully creates game with nonexisting user and redirects", %{conn: conn, user: user} do
    attrs = %{other_user_name: "foo", other_user_type: "nonexisting"}

    conn = post conn, game_path(conn, :create, game: attrs)
    [game] = Data.list_user_created_games(user)

    assert redirected_to(conn) == game_path(conn, :index)
    assert game.user_id == user.id and game.other_user_name == "foo"
  end

  @tag login_as: "bob"
  test ":create fails, does not create game, and redirects", %{conn: conn, user: _} do
    attrs = %{other_user_name: nil, other_user_type: nil}

    conn = post conn, game_path(conn, :create, game: attrs)
    assert html_response(conn, 200) =~ ~r/can&#39;t be blank/
  end

  @tag login_as: "bob"
  test ":new shows recently played with usernames", %{conn: conn, user: user} do
    {:ok, _} = insert_game(user, %{other_user_name: "other1"})
    {:ok, _} = insert_game(user, %{other_user_name: "other2"})

    conn = get conn, game_path(conn, :new)
    assert html_response(conn, 200) =~ "other1"
    assert String.contains?(conn.resp_body, "other2")
  end

  @tag login_as: "bob"
  test ":delete successfully deletes game created by logged in player", %{conn: conn, user: user} do
    {:ok, game} = insert_game(user, %{other_user_name: "dave"})
    before_count = count_games()

    conn = delete conn, game_path(conn, :delete, game.id)
    assert redirected_to(conn) == game_path(conn, :index)
    assert get_flash(conn, :info) == "Game deleted successfully"

    after_count = count_games()
    assert after_count == before_count - 1
  end

  @tag login_as: "bob"
  test ":delete successfully deletes game created by other player", %{conn: conn, user: _} do
    {:ok, other} = insert_user(%{username: "dave"})
    {:ok, game} = insert_game(other, %{other_user_name: "bob", other_user_type: "existing"})
    before_count = count_games()

    conn = delete conn, game_path(conn, :delete, game.id)
    assert redirected_to(conn) == game_path(conn, :index)
    assert get_flash(conn, :info) == "Game deleted successfully"

    after_count = count_games()
    assert after_count == before_count - 1
  end

  @tag login_as: "bob"
  test ":delete fails and redirects if user is not a player in the game", %{conn: conn, user: _} do
    {:ok, other} = insert_user(%{username: "dave"})

    {:ok, game} = insert_game(other, %{other_user_name: "sarah"})

    conn = delete conn, game_path(conn, :delete, game.id)
    assert redirected_to(conn) == game_path(conn, :index)
    assert get_flash(conn, :error) == "Invalid game id"
  end

  @tag login_as: "bob"
  test ":finish successfully sets winner of the other player", %{conn: conn, user: user} do
    {:ok, other} = insert_user(%{username: "dave"})

    {:ok, game1} = insert_game(other, %{other_user_name: "bob", other_user_type: "existing"})
    {:ok, game2} = insert_game(user, %{other_user_name: "dave", other_user_type: "existing"})

    next_conn = post conn, game_path(conn, :finish, game1.id)
    assert redirected_to(next_conn) == game_path(conn, :index)
    assert get_flash(next_conn, :info) == "Game forfeited successfully"

    next_conn = post conn, game_path(conn, :finish, game2.id)
    assert redirected_to(next_conn) == game_path(conn, :index)
    assert get_flash(next_conn, :info) == "Game forfeited successfully"
  end

  @tag login_as: "bob"
  test ":finish fails and redirects if user is not a player in the game", %{conn: conn, user: _} do
    {:ok, other} = insert_user(%{username: "dave"})

    {:ok, game} = insert_game(other, %{other_user_name: "sarah"})

    conn = post conn, game_path(conn, :finish, game.id)
    assert redirected_to(conn) == game_path(conn, :index)
    assert get_flash(conn, :error) == "Invalid game id"
  end

  @tag login_as: "bob"
  test ":show fails if user doesn't own game", %{conn: conn, user: _} do
    {:ok, other} = insert_user(%{username: "dave"})
    {:ok, game} = insert_game(other, %{other_user_name: "sarah"})

    assert_error_sent :not_found, fn ->
      get conn, game_path(conn, :show, game.id)
    end
  end

  defp count_games() do
    import Ecto.Query
    PathfinderWeb.Repo.one(
      from g in PathfinderWeb.Data.Game, select: count(g.id)
    )
  end
end
