defmodule Pathfinder.EtsStore do
  alias Pathfinder.EtsStore

  defstruct [:games]

  def new(games_table) do
    :ets.new(games_table, [:named_table, read_concurrency: true])
    %EtsStore{games: games_table}
  end

  defimpl Pathfinder.Store do
    def get(%{games: games}, id) do
      case :ets.lookup(games, id) do
        [game] -> game
        [] -> nil
      end
    end

    def set(store, id, game) do
      raise "Not implemented"
    end

    def delete(store, id) do
      raise "Not implemented"
    end
  end
end
