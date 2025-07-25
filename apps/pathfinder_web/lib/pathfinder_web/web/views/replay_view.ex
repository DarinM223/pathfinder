defmodule PathfinderWeb.Web.ReplayView do
  use PathfinderWeb.Web, :view

  import PathfinderWeb.Web.GameView, only: [make_game_names: 2, player_id: 1]

  def replay_changes(changes) do
    changes
    |> Enum.map(&clean_data/1)
    |> Jason.encode!()
  end

  defp clean_data(%{name: name, args: args, user_id: user_id}) do
    %{
      name: name,
      params: Map.get(args, "params"),
      user_id: user_id
    }
  end
end
