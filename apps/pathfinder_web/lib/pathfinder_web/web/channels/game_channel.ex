defmodule PathfinderWeb.Web.GameChannel do
  use PathfinderWeb.Web, :channel

  alias PathfinderWeb.Accounts
  alias PathfinderWeb.Data
  alias PathfinderWeb.Web.PlayerView

  def join("games:" <> game_id, params, socket) do
    game_id = game_id |> Integer.parse() |> elem(0)
    if id = Pathfinder.full_game_id(game_id) do
      game = Pathfinder.state(id)
      player = get_in(game, [:players, socket.assigns.user_id])
      rendered_player = Phoenix.View.render(PlayerView, "player.json", %{
        id: socket.assigns.user_id,
        player: player,
        state: game.state,
      })
      {:ok, rendered_player, assign(socket, :game_id, id)}
    else
      user = Accounts.get_user!(socket.assigns.user_id)
      game = Data.get_user_game!(user, game_id)
      other_player_id = game.other_user_id
      {:ok, id} = Pathfinder.add(game_id, socket.assigns.user_id, other_player_id)
      {:ok, nil, assign(socket, :game_id, id)}
    end
  end

  def handle_in(action, params, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id
    handle_in(action, params, game_id, user_id, socket)
  end

  def handle_in("build", %{"changes" => changes}, game_id, user_id, socket) do
    changes = Enum.map(changes, &convert_action/1)
    case Pathfinder.build(game_id, user_id, changes) do
      {:turn, next_player_id} ->
        game = Pathfinder.state(game_id)
        next_player = get_in(game, [:players, next_player_id])
        # TODO(DarinM223): render only the state
        rendered_player = Phoenix.View.render(PlayerView, "player.json", %{
          id: next_player_id,
          player: next_player,
          state: game.state
        })

        broadcast! socket, "next", rendered_player
        {:reply, :ok, socket}
      :ok ->
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("turn", %{"action" => action}, game_id, user_id, socket) do
    result = Pathfinder.turn(game_id, user_id, action)
    IO.puts("Result: #{result}")
    case result do
      :ok ->
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  @allowed_actions ["place_goal", "set_wall", "place_player", "remove_player", "move_player"]

  defp convert_action(%{"name" => name, "params" => params})
      when is_binary(name) and is_list(params) and name in @allowed_actions do
    convert_to_tuples = fn
      l when is_list(l) -> List.to_tuple(l)
      e -> e
    end

    {String.to_atom(name), Enum.map(params, convert_to_tuples)}
  end
end
