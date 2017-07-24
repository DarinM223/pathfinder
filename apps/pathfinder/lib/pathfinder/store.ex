defprotocol Pathfinder.Store do
  @moduledoc """
  Interface for storing games.
  """

  @doc """
  Retrieves a game from the store.
  """
  def get(store, id)

  @doc """
  Saves a game to the store.
  """
  def set(store, id, game)

  @doc """
  Deletes a game from the store.
  """
  def delete(store, id)
end
