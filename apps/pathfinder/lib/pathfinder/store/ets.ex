defmodule Pathfinder.Store.Ets do
  alias Pathfinder.Store.Ets

  defstruct [:games]

  def new(games_table) do
    :ets.new(games_table, [:set, :named_table])
    %Ets{games: games_table}
  end

  defimpl Pathfinder.Store do
    def get(%{games: games}, id) do
      case :ets.lookup(games, id) do
        [{_, game}] -> game
        [] -> nil
      end
    end

    def set(%{games: games} = store, id, game) do
      :ets.insert(games, {id, game})
      store
    end

    def delete(%{games: games} = store, id) do
      :ets.delete(games, id)
      store
    end
  end
end
