defmodule PathfinderWeb.Web.PlayView do
  use PathfinderWeb.Web, :view

  import PathfinderWeb.Web.GameView, only: [player_id: 1, replay_link: 2]
end
