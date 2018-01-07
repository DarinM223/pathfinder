defmodule Pathfinder.AI do
  @moduledoc """
  An implementation of Pathfinder AI.
  """

  alias Pathfinder.AI
  alias Pathfinder.Board

  @column_size Application.get_env(:pathfinder, :column_size)

  defstruct tried_entry_rows: MapSet.new(),
    visited: MapSet.new(),
    # Links are attempts to move from one cell to another
    # and are represented by a tuple of two positions.
    tried_links: MapSet.new(),
    move_stack: []

  @doc """
  Creates a new AI instance.
  """
  def new do
    %AI{}
  end

  @doc """
  Suggests a move. It returns the updated AI instance, a boolean that is false when backtracking,
  and the suggested move.
  """
  def move(%AI{move_stack: [], tried_entry_rows: tried_rows} = ai, board) do
    random_row = Enum.random(1..@column_size)
    if MapSet.member?(tried_rows, random_row) do
      move(ai, board)
    else
      ai = %{ai | tried_entry_rows: MapSet.put(tried_rows, random_row)}
      {ai, true, {:place_player, [random_row]}}
    end
  end
  def move(%AI{move_stack: [top | rest], visited: visited, tried_links: tried_links} = ai, board) do
    unvisited_neighbors =
      neighbors(top, board)
      |> Stream.filter(&filter_visited(visited, tried_links, {top, &1}))
      |> Enum.shuffle()

    if length(unvisited_neighbors) > 0 do
      unvisited = List.first(unvisited_neighbors)
      tried_links =
        tried_links
        |> MapSet.put({top, unvisited})
        |> MapSet.put({unvisited, top})
      ai = %{ai | tried_links: tried_links}

      {:ok, direction} = Board.direction_between_points(top, unvisited)
      {ai, true, {:move_player, [direction, top]}}
    else
      if length(rest) > 0 do
        {:ok, direction} = Board.direction_between_points(top, List.first(rest))
        {ai, false, {:move_player, [direction, top]}}
      else
        {ai, false, {:remove_player, []}}
      end
    end
  end

  @doc """
  Callback called when a move successfully completed.
  """
  def move_success(%AI{visited: visited, move_stack: move_stack} = ai, true, {:place_player, [row]}) do
    pos = {row, 1}
    visited = MapSet.put(visited, pos)
    %{ai | visited: visited, move_stack: [pos | move_stack]}
  end
  def move_success(%AI{visited: visited, move_stack: move_stack} = ai, true, {:move_player, [dir, pos]}) do
    {:ok, next_pos} = Board.next(pos, dir)
    visited = MapSet.put(visited, next_pos)
    %{ai | visited: visited, move_stack: [next_pos | move_stack]}
  end
  def move_success(%AI{move_stack: [_ | rest]} = ai, false, _) do
    %{ai | move_stack: rest}
  end

  defp filter_visited(visited, tried_links, {top, unvisited}) do
    not MapSet.member?(tried_links, {top, unvisited}) and not MapSet.member?(visited, unvisited)
  end

  defp neighbors(cell, board) do
    Board.valid_neighbors(cell)
    |> Stream.filter(fn {dir, _} -> Board.can_move(board, cell, dir) end)
    |> Enum.map(&elem(&1, 1))
  end
end
