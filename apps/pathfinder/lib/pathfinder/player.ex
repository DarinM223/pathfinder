defprotocol Pathfinder.Player do
  @moduledoc """
  Describes a pathfinder player.
  """

  @doc """
  Returns a list of changes necessary to build their grid.
  """
  def build_changes(player)

  @doc """
  Returns the action to perform.
  """
  def move(player)

  @doc """
  Updates the player after the result
  of the action is determined.
  """
  def update(player, result)
end
