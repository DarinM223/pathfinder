defmodule Pathfinder.Board do
  @moduledoc """
  Describes a pathfinder board.

  A pathfinder board is a 6x6 board with each cell
  having slots around the edges where tiles can be placed
  to form walls.

  Each board automatically has walls around three of
  the four edges that cannot be removed.

  A board is represented by a map of index to cells.
  A cell is represented as a five element tuple with
  the first element being the data and the other elements
  being the top, right, bottom, and left walls respectively.
  """

  @row_size 6
  @column_size 6

  @doc """
  Creates an empty board.
  """
  def new do
    (for row <- 1..@column_size,
         col <- 1..@row_size,
         do: {row, col})
    |> Stream.map(fn {row, col} ->
         cond do
           col == @row_size and row == 1 ->
             {nil, true, true, false, false} # Walls: top & right
           col == @row_size and row == @column_size ->
             {nil, false, true, true, false} # Walls: bottom & right
           col == @row_size ->
             {nil, false, true, false, false} # Walls: right
           row == 1 ->
             {nil, true, false, false, false} # Walls: top
           row == @column_size ->
             {nil, false, false, true, false} # Walls: bottom
           true ->
             {nil, false, false, false, false}
         end
       end)
    |> Stream.with_index(0)
    |> Enum.reduce(%{}, fn {cell, index}, acc ->
         Map.put(acc, index, cell)
       end)
  end

  @doc """
  Prints a board to the console.

      iex> alias Pathfinder.Board
      iex> Board.to_io_list(Board.new())
      iex> nil
      nil

  """
  def to_io_list(board) do
    for r <- 1..@column_size do
      row =
        1..@row_size
        |> Stream.map(&index(r, &1))
        |> Enum.map(&Map.get(board, &1))

      if r == 1 do
        [top_row(row), middle_row(row), bottom_row(row)]
      else
        [middle_row(row), bottom_row(row)]
      end
    end
  end

  defp top_row([{_, top, _, _, _} | tail]) do
    if top do
      ["+---", top_row(tail)]
    else
      ["+   ", top_row(tail)]
    end
  end
  defp top_row(_), do: "+\n"

  defp middle_row([{data, _, _, _, left} | tail]) do
    left_wall = if left, do: "|", else: " "
    data = if data, do: "0", else: " "

    [left_wall, " ", data, " ", middle_row(tail)]
  end
  defp middle_row(_), do: "|\n"

  defp bottom_row([{_, _, _, bottom, _} | tail]) do
    if bottom do
      ["+---", bottom_row(tail)]
    else
      ["+   ", bottom_row(tail)]
    end
  end
  defp bottom_row(_), do: "+\n"

  @doc """
  Returns the index of the row and column position in the board.
  The rows and columns are one-indexed.
  """
  def index(cell_row, cell_col) do
    (cell_row - 1) * @row_size + (cell_col - 1)
  end

  @doc """
  Places a wall on a board.
  """
  def place_wall(board, {row, col}, slot_position) do
    raise "Not implemented"
  end

  @doc """
  Removes a wall on the board.

  Fails if a wall doesn't exist at the given position or
  if the wall is an edge wall.
  """
  def remove_wall(board, {row, col}, slot_position) do
    raise "Not implemented"
  end

  @doc """
  Places a player on a row in the board.
  """
  def place_player(board, row) do
    raise "Not implemented"
  end

  @doc """
  Moves a player in the given direction.

  Directions can be :up, :down, :left, or :right
  """
  def move_player(board, direction) do
    # TODO(DarinM223): remove player from existing position
    # TODO(DarinM223): place a marker in the existing position
    # TODO(DarinM223): place player in new position
    raise "Not implemented"
  end

  # Place an object at the given position.
  defp place(board, obj, cell_index) do
    raise "Not implemented"
  end
end
