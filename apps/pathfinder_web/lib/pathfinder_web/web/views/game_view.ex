defmodule PathfinderWeb.Web.GameView do
  use PathfinderWeb.Web, :view

  alias PathfinderWeb.Web.Router

  def player_id(conn) do
    if conn.assigns.current_user do
      conn.assigns.current_user.id
    else
      -1
    end
  end

  def share_link(conn, game) do
    if conn.assigns.current_user.id == game.user_id and game.other_user_id == -1 do
      Router.Helpers.url(conn) <> "/play/#{game.shareid}"
    else
      nil
    end
  end

  @doc """
  Creates the names for each game accounting for duplicate usernames.

  Games names with duplicate usernames created after will have (2), (3), ...etc
  appended after it.

  Returns a map of game ids to game names given a list of
  games and a function that returns a username given a game.
  """
  def make_game_names(games, username_fn) do
    games
    |> Enum.reverse()
    |> _make_game_names(username_fn, %{}, %{})
  end

  defp _make_game_names([game | rest], username_fn, count_map, name_map) do
    {count, count_map} = Map.get_and_update(count_map, username_fn.(game), fn
      nil -> {nil, 1}
      count -> {count + 1, count + 1}
    end)

    game_name =
      if count == nil do
        username_fn.(game)
      else
        "#{username_fn.(game)} (#{count})"
      end
    name_map = Map.put(name_map, game.id, game_name)
    _make_game_names(rest, username_fn, count_map, name_map)
  end
  defp _make_game_names([], _username_fn, _count_map, name_map), do: name_map
end
