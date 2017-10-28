defmodule Pathfinder.AI do
  alias Pathfinder.AI
  alias Pathfinder.Board

  @column_size Application.get_env(:pathfinder, :column_size)

  defstruct tried_entry_rows: MapSet.new(),
    tried_cells: MapSet.new(),
    move_stack: []

  @doc """
  Creates a new AI instance.
  """
  def new do
    %AI{}
  end

  def move(%AI{move_stack: [], tried_entry_rows: tried_rows} = ai, board) do
    random_row = Enum.random(1..@column_size)
    if MapSet.member?(tried_rows, random_row) do
      move(ai, board)
    else
      ai = %{ai | tried_entry_rows: MapSet.put(tried_rows, random_row)}
      {ai, true, {:place_player, [random_row]}}
    end
  end
  def move(%AI{move_stack: [top | rest], tried_cells: tried_cells} = ai, board) do
    unvisited_neighbors = Enum.filter(
      neighbors(top, board),
      &(not MapSet.member?(tried_cells, {top, &1}))
    )

    if length(unvisited_neighbors) > 0 do
      unvisited = List.first(unvisited_neighbors)
      tried_cells =
        tried_cells
        |> MapSet.put({top, unvisited})
        |> MapSet.put({unvisited, top})
      ai = %{ai | tried_cells: tried_cells}

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
  def move_success(%AI{move_stack: move_stack} = ai, true, {:place_player, [row]}) do
    %{ai | move_stack: [{row, 1} | move_stack]}
  end
  def move_success(%AI{move_stack: move_stack} = ai, true, {:move_player, [dir, pos]}) do
    {:ok, next_pos} = Board.next(pos, dir)
    %{ai | move_stack: [next_pos | move_stack]}
  end
  def move_success(%AI{move_stack: [_ | rest]} = ai, false, _) do
    %{ai | move_stack: rest}
  end

  defp neighbors(cell, board) do
    Board.valid_neighbors(cell)
    |> Stream.filter(fn {dir, pos} -> Board.can_move(board, cell, dir) end)
    |> Enum.map(&elem(&1, 1))
  end
end
