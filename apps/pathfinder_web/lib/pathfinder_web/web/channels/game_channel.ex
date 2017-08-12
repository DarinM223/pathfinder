defmodule PathfinderWeb.Web.GameChannel do
  use PathfinderWeb.Web, :channel

  alias PathfinderWeb.Data
  alias PathfinderWeb.Web.PlayerView

  def join("games:" <> game_id, _params, socket) do
    game_id = game_id |> Integer.parse() |> elem(0)
    game = Data.get_game!(game_id)
    user_id = socket.assigns.user_id

    if is_valid_user?(game, user_id) do
      handle_user_join(Pathfinder.full_game_id(game_id),
                       game, user_id, socket)
    else
      {:error, "User is not a player in this game"}
    end
  end

  defp is_valid_user?(game, user_id) do
    user_id == game.user_id or user_id == game.other_user_id
  end

  defp handle_user_join(nil, game, _, socket) do
    {:ok, id} = Pathfinder.add(game.id, game.user_id, game.other_user_id)
    {:ok, nil, assign(socket, :game_id, id)}
  end
  defp handle_user_join(worker_id, _, user_id, socket) do
    game = Pathfinder.state(worker_id)
    player = get_in(game, [:players, user_id])
    rendered_player = Phoenix.View.render(PlayerView, "player.json", %{
      id: user_id,
      player: player,
      state: game.state,
    })

    {:ok, rendered_player, assign(socket, :game_id, worker_id)}
  end

  def handle_in(action, params, socket) do
    game_id = socket.assigns.game_id
    user_id = socket.assigns.user_id
    handle_in(action, params, game_id, user_id, socket)
  end

  def handle_in("build", %{"changes" => changes}, game_id, user_id, socket) do
    changes = Enum.map(changes, &convert_action/1)
    case Pathfinder.build(game_id, user_id, changes) do
      {:turn, _} ->
        game = Pathfinder.state(game_id)

        broadcast! socket, "next", %{changes: [], state: Tuple.to_list(game.state)}
        {:reply, :ok, socket}
      :ok ->
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("turn", %{"action" => action}, game_id, user_id, socket) do
    converted_action = convert_action(action)
    case Pathfinder.turn(game_id, user_id, converted_action) do
      {:win, user_id} ->
        game = Pathfinder.state(game_id)

        broadcast! socket, "next", %{changes: [action], state: Tuple.to_list(game.state)}
        # Update game winner in database.
        {:ok, _} =
          game_id
          |> elem(1)
          |> Data.get_game!()
          |> Data.update_game(%{winner: user_id})
        {:reply, :ok, socket}
      {:turn, _} ->
        game = Pathfinder.state(game_id)

        broadcast! socket, "next", %{changes: [action], state: Tuple.to_list(game.state)}
        {:reply, :ok, socket}
      _ ->
        game = Pathfinder.state(game_id)

        broadcast! socket, "next", %{changes: [], state: Tuple.to_list(game.state)}
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
