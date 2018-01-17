defmodule Pathfinder.Board.Walls do
  @moduledoc """
  Builder that creates a list of Board changes
  to make a randomly generated maze.
  """

  alias Pathfinder.Board

  @doc """
  Returns a new walls instance with all walls in the grid set
  except for the left walls in the first column.
  """
  def set_all(row_size, column_size) do
    cells =
      for row <- 1..column_size,
          col <- 1..row_size,
          do: {row, col}

    Enum.reduce(cells, MapSet.new(), fn {row, col}, walls ->
      neighbors = Board.valid_neighbors({row, col}) |> Stream.map(&elem(&1, 1))

      Enum.reduce(neighbors, walls, fn pos, walls ->
        MapSet.put(walls, {{row, col}, pos})
      end)
    end)
  end

  @doc """
  Removes random walls from a walls instance.
  """
  def remove_random(walls, {row, col}) do
    _remove_random(walls, {row, col}, %{}) |> elem(0)
  end

  defp _remove_random(walls, {row, col}, visited) do
    visited = Map.put(visited, Board.index(row, col), true)

    neighbors =
      Board.valid_neighbors({row, col})
      |> Stream.map(&elem(&1, 1))
      |> Enum.shuffle()

    Enum.reduce(neighbors, {walls, visited}, fn cell, {walls, visited} ->
      if not Map.has_key?(visited, Board.index(cell)) do
        walls =
          walls
          |> MapSet.delete({{row, col}, cell})
          |> MapSet.delete({cell, {row, col}})

        _remove_random(walls, cell, visited)
      else
        {walls, visited}
      end
    end)
  end

  @doc """
  Adds random row walls, excluding the entry row.
  """
  def add_random_row_walls(walls, col_size, entry_row) do
    Enum.reduce(1..col_size, walls, fn row, walls ->
      if row != entry_row and Enum.random(0..1) == 1 do
        MapSet.put(walls, row)
      else
        walls
      end
    end)
  end

  @doc """
  Converts the walls into a list of :set_wall changes that
  can be applied by a Board.
  """
  def to_change_list(walls) do
    Enum.reduce(walls, [], fn
      {pos1, pos2}, list -> [{:set_wall, [pos1, pos2, true]} | list]
      row, list -> [{:set_wall, [row, true]} | list]
    end)
  end
end
