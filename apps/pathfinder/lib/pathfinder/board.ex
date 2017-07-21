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

      iex> board = Pathfinder.Board.new()
      iex> board |> Map.keys() |> length == (36 + 2)
      true

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
    |> Map.put(:player, nil)
    |> Map.put(:goal, nil)
  end

  @doc """
  Prints a board to the console.

  ## Example

      iex> alias Pathfinder.Board
      iex> s = Board.new() |> Board.to_io_list() |> Enum.join()
      iex> is_binary(s)
      true

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
    data =
      case data do
        :player -> " P "
        :goal -> " G "
        :marker -> " 0 "
        _ -> "   "
      end

    [left_wall, data, middle_row(tail)]
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
  Returns the index of the row and column position in the board
  or -1 if the row or column is invalid.
  The rows and columns are one-indexed.

  ## Examples

      iex> Pathfinder.Board.index(6, 6)
      35

      iex> Pathfinder.Board.index(1, 1)
      0

      iex> Pathfinder.Board.index({1, 1})
      0

      iex> Pathfinder.Board.index(0, 1)
      -1

  """
  def index(cell_row, cell_col)
      when cell_row > 0 and cell_row <= @column_size and
           cell_col > 0 and cell_col <= @row_size do
    (cell_row - 1) * @row_size + (cell_col - 1)
  end
  def index(_, _), do: -1
  def index({cell_row, cell_col}) do
    index(cell_row, cell_col)
  end

  @doc """
  Sets a wall on the board.
  """
  def set_wall(board, row, value) do
    i = index(row, 1)
    with {:ok, cell} <- Map.fetch(board, i) do
      cell = Kernel.put_elem(cell, 4, value)
      {:ok, Map.put(board, i, cell)}
    end
  end
  def set_wall(board, {row1, col1}, {row2, col2}, value) do
    index1 = index(row1, col1)
    index2 = index(row2, col2)

    direction =
      cond do
        row1 == row2 - 1 -> {:ok, 3} # bottom
        row2 == row1 - 1 -> {:ok, 1} # top
        col1 == col2 - 1 -> {:ok, 2} # right
        col2 == col1 - 1 -> {:ok, 4} # left
        true -> {:error, :invalid_cells}
      end

    with {:ok, direction} <- direction,
         {:ok, cell1} <- Map.fetch(board, index1),
         {:ok, cell2} <- Map.fetch(board, index2) do
      cell1 = Kernel.put_elem(cell1, direction, value)
      cell2 = Kernel.put_elem(cell2, reverse(direction), value)
      board =
        board
        |> Map.put(index1, cell1)
        |> Map.put(index2, cell2)
      {:ok, board}
    end
  end

  @doc """
  Reverses a direction.

  A direction is given by its index in the tuple
  {_, top, right, bottom, left}.

  ## Examples

      iex> Pathfinder.Board.reverse(1) # top -> bottom
      3

      iex> Pathfinder.Board.reverse(4) # left -> right
      2

  """
  def reverse(direction) do
    case direction do
      1 -> 3
      2 -> 4
      3 -> 1
      4 -> 2
      _ -> raise "Invalid direction: #{inspect direction}"
    end
  end

  @doc """
  Places a player on a row in the board.
  """
  def place_player(board, row) do
    i = index(row, 1)
    with {:ok, {_, _, _, _, left} = cell} <- Map.fetch(board, i) do
      if left do
        {:error, :wall}
      else
        board =
          board
          |> Map.put(i, Kernel.put_elem(cell, 0, :player))
          |> Map.put(:player, {row, 1})
        {:ok, board}
      end
    end
  end

  @doc """
  Removes the player from the board.
  Only works if the player is next to a row entry
  (a row on the first column) that does not have a left wall.
  """
  def remove_player(board) do
    with {row, col} when col == 1 <- Map.get(board, :player),
         pos_index <- index(row, col),
         {:ok, cell} when not elem(cell, 4) <- Map.fetch(board, pos_index) do
      board =
        board
        |> Map.put(pos_index, Kernel.put_elem(cell, 0, :marker))
        |> Map.put(:player, nil)
      {:ok, board}
    else
      _ -> :error
    end
  end

  @doc """
  Places the goal on a cell in the board.
  """
  def place_goal(board, position) do
    i = index(position)
    with {:ok, cell} <- Map.fetch(board, i) do
      board =
        board
        |> Map.put(i, Kernel.put_elem(cell, 0, :goal))
        |> Map.put(:goal, position)
      {:ok, board}
    end
  end

  @doc """
  Moves a player in the given direction.
  """
  def move_player(board, direction) do
    # TODO(DarinM223): remove player from existing position
    # TODO(DarinM223): place a marker in the existing position
    # TODO(DarinM223): place player in new position
    raise "Not implemented"
  end
end
