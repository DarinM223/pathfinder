defmodule PathfinderWeb.Web.GameChannel do
  use PathfinderWeb.Web, :channel

  alias PathfinderWeb.Data
  alias PathfinderWeb.Web.ActionView
  alias PathfinderWeb.Web.PlayerView

  def join("games:" <> game_id, _params, socket) do
    game_id = game_id |> Integer.parse() |> elem(0)
    game = Data.get_game!(game_id)
    user_id = socket.assigns.user_id

    if is_valid_user?(game, user_id) do
      handle_user_join(
        Pathfinder.worker_id(game_id),
        game,
        user_id,
        socket
      )
    else
      {:error, "User is not a player in this game"}
    end
  end

  defp is_valid_user?(game, user_id) do
    user_id == game.user_id or user_id == game.other_user_id
  end

  # Create new worker if one doesn't exist.
  defp handle_user_join(nil, game, _, socket) do
    {:ok, id} = Pathfinder.add(game.id, game.user_id, game.other_user_id)
    {:ok, nil, assign(socket, :worker_id, id)}
  end
  # If worker exists, reply with serialized player state.
  defp handle_user_join(worker_id, _, user_id, socket) do
    worker_state = Pathfinder.state(worker_id)
    player = get_in(worker_state, [:players, user_id])
    rendered_player = Phoenix.View.render(PlayerView, "player.json", %{
      id: user_id,
      player: player,
      state: worker_state.state,
    })

    {:ok, rendered_player, assign(socket, :worker_id, worker_id)}
  end

  def handle_in(action, params, socket) do
    worker_id = socket.assigns.worker_id
    user_id = socket.assigns.user_id
    handle_in(action, params, worker_id, user_id, socket)
  end

  def handle_in("build", %{"changes" => changes}, worker_id, user_id, socket) do
    changes = Enum.map(changes, &convert_action/1)
    case Pathfinder.build(worker_id, user_id, changes) do
      {:turn, _} ->
        worker_state = Pathfinder.state(worker_id)
        broadcast! socket, "next", %{
          changes: [],
          state: Tuple.to_list(worker_state.state)
        }

        {:reply, :ok, socket}
      :ok ->
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("turn", %{"action" => action}, worker_id, user_id, socket) do
    converted_action = convert_action(action)
    turn_result = Pathfinder.turn(worker_id, user_id, converted_action)
    worker_state = Pathfinder.state(worker_id)

    case turn_result do
      {:win, user_id} ->
        broadcast! socket, "next", %{
          changes: [action],
          state: Tuple.to_list(worker_state.state)
        }

        handle_win(worker_id, user_id)
        {:reply, :ok, socket}
      {:turn, _} ->
        broadcast! socket, "next", %{
          changes: [action],
          state: Tuple.to_list(worker_state.state)
        }

        {:reply, :ok, socket}
      _ ->
        broadcast! socket, "next", %{
          changes: [],
          state: Tuple.to_list(worker_state.state)
        }

        {:reply, :error, socket}
    end
  end

  defp handle_win(worker_id, winner_id) do
    game = worker_id |> elem(1) |> Data.get_game!()
    history = Pathfinder.state(worker_id).history
    attrs_list = Enum.reduce(history, [], fn {user_id, name, params}, attrs_list ->
      change = Phoenix.View.render(ActionView, "action.json", %{
        action: {name, params}
      })

      time = Ecto.DateTime.utc
      change =
        change
        |> Map.put(:user_id, user_id)
        |> Map.put(:game_id, game.id)
        |> Map.put(:inserted_at, time)
        |> Map.put(:updated_at, time)
      [change | attrs_list]
    end)

    Data.update_on_win(game, winner_id, attrs_list)
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
