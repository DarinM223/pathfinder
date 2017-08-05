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
    case Pathfinder.build(game_id, user_id, changes) do
      :ok ->
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end

  def handle_in("turn", %{"action" => action}, game_id, user_id, socket) do
    case Pathfinder.turn(game_id, user_id, action) do
      :ok ->
        {:reply, :ok, socket}
      _ ->
        {:reply, :error, socket}
    end
  end
end
