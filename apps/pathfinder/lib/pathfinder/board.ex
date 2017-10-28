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

  @row_size Application.get_env(:pathfinder, :row_size)
  @column_size Application.get_env(:pathfinder, :column_size)
  @directions [
    1, # Top
    2, # Right
    3, # Bottom
    4  # Left
  ]

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
    |> _init_board()
  end

  @doc """
  Creates a board with a random maze.

  Uses the recursive backtracking algorithm described in:
  https://en.wikipedia.org/wiki/Maze_generation_algorithm
  """
  def generate do
    cells =
      for _ <- 1..@column_size, col <- 1..@row_size do
        if col == 1 do
          {nil, true, true, true, false}
        else
          {nil, true, true, true, true}
        end
      end

    cells
    |> _init_board()
    |> _generate_maze({1, 1}, %{})
    |> elem(0)
    |> _set_goal()
  end

  # Sets the goal to a random position in the maze.
  defp _set_goal(board) do
    goal_pos = {Enum.random(1..@column_size), Enum.random(1..@row_size)}

    board
    |> Map.update(index(goal_pos), nil, &Kernel.put_elem(&1, 0, :goal))
    |> Map.put(:goal, goal_pos)
  end

  # Recursive backtracking algorithm for randomly generating maze.
  defp _generate_maze(board, {row, col}, visited) do
    visited = Map.put(visited, index(row, col), true)
    neighbors =
      @directions
      |> Stream.map(&next({row, col}, &1))
      |> Stream.filter(fn {:ok, _} -> true; _ -> false end)
      |> Stream.map(&elem(&1, 1))
      |> Enum.shuffle()

    Enum.reduce(neighbors, {board, visited}, fn cell, {board, visited} ->
      if not Map.has_key?(visited, index(cell)) do
        {:ok, board} = set_wall(board, {row, col}, cell, false)
        _generate_maze(board, cell, visited)
      else
        {board, visited}
      end
    end)
  end

  # Converts a board to from a list of cells to a map of indexes to cells
  # and sets the player and goal to nil.
  defp _init_board(cells) do
    cells
    |> Stream.with_index(0)
    |> Enum.reduce(%{}, fn {cell, index}, acc ->
         Map.put(acc, index, cell)
       end)
    |> Map.put(:player, nil)
    |> Map.put(:goal, nil)
  end

  @doc """
  Returns a stream of all valid neighbors and their directions to a given cell.

      iex> Enum.to_list(Pathfinder.Board.valid_neighbors({1, 1}))
      [{2, {1, 2}}, {3, {2, 1}}]

      iex> Enum.to_list(Pathfinder.Board.valid_neighbors({-1, -1}))
      []

  """
  def valid_neighbors(cell) do
    @directions
    |> Stream.map(&{&1, next(cell, &1)})
    |> Stream.filter(fn {_, {:ok, _}} -> true; _ -> false end)
    |> Stream.map(fn {dir, {:ok, pos}} -> {dir, pos} end)
  end

  @doc """
  Returns the console printable version of the board as an IO list.

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

  # Validates that the row and column are inside the bounds of the grid.
  defmacro validate_position(row, col) do
    quote do
      unquote(row) > 0 and unquote(row) <= @column_size and
      unquote(col) > 0 and unquote(col) <= @row_size
    end
  end

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
  def index(cell_row, cell_col) when validate_position(cell_row, cell_col) do
    (cell_row - 1) * @row_size + (cell_col - 1)
  end
  def index(_, _), do: -1
  def index({cell_row, cell_col}), do: index(cell_row, cell_col)

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
  def set_wall(board, pos1, pos2, value) do
    index1 = index(pos1)
    index2 = index(pos2)

    with {:ok, direction} <- direction_between_points(pos1, pos2),
         {:ok, cell1} <- Map.fetch(board, index1),
         {:ok, cell2} <- Map.fetch(board, index2) do
      cell1 = Kernel.put_elem(cell1, direction, value)
      cell2 = Kernel.put_elem(cell2, reverse(direction), value)
      board =
        board
        |> Map.put(index1, cell1)
        |> Map.put(index2, cell2)
      {:ok, board}
    else
      _ -> :error
    end
  end

  @doc """
  Finds the direction between two positions in the board.

  ## Examples

      iex> Pathfinder.Board.direction_between_points({1, 1}, {1, 2})
      {:ok, 2}

      iex> Pathfinder.Board.direction_between_points({1, 1}, {1, 3})
      :error

  """
  def direction_between_points(pos1, {row2, col2}) do
    # Find the direction between the cells by applying every
    # direction to the first cell and filtering the cells
    # that don't match the second cell.
    #
    # Inefficient, but keeps direction details contained inside next().
    possible_directions =
      valid_neighbors(pos1)
      |> Stream.filter(fn {_, e} -> e == {row2, col2} end)
      |> Enum.map(&elem(&1, 0))

    if length(possible_directions) > 0 do
      {:ok, List.first(possible_directions)}
    else
      :error
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
  Returns the next position after applying a direction.

  A direction is given by its index in the tuple
  {_, top, right, bottom, left}.

  ## Examples

      iex> Pathfinder.Board.next({3, 5}, 4)
      {:ok, {3, 4}}

      iex> Pathfinder.Board.next({1, 1}, 4)
      :error

  """
  def next({row, col}, direction) do
    {row, col} =
      case direction do
        1 -> {row - 1, col}
        2 -> {row, col + 1}
        3 -> {row + 1, col}
        4 -> {row, col - 1}
        _ -> raise "Invalid direction: #{inspect direction}"
      end

    if validate_position(row, col) do
      {:ok, {row, col}}
    else
      :error
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
  def remove_player(board, _), do: remove_player(board)

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
  Return true if it is possible to move in a direction starting
  from a position, false otherwise.

      iex> Pathfinder.Board.can_move(Pathfinder.Board.new(), {1, 1}, 2)
      true

      iex> board = Pathfinder.Board.new()
      iex> {:ok, board} = Pathfinder.Board.set_wall(board, {1, 1}, {1, 2}, true)
      iex> Pathfinder.Board.can_move(board, {1, 1}, 2)
      false

      iex> Pathfinder.Board.can_move(Pathfinder.Board.new(), {-1, -1}, 2)
      false

  """
  def can_move(board, pos, direction) do
    pos_index = index(pos)
    case Map.fetch(board, pos_index) do
      {:ok, cell} when not elem(cell, direction) -> true
      _ -> false
    end
  end

  @doc """
  Moves a player in the given direction.
  """
  def move_player(board, direction) do
    with {row, col} <- Map.get(board, :player),
         pos_index <- index(row, col),
         {:ok, next_pos} <- next({row, col}, direction),
         {:ok, cell} when not elem(cell, direction) <- Map.fetch(board, pos_index) do
      next_pos_index = index(next_pos)
      board =
        board
        |> Map.put(pos_index, Kernel.put_elem(cell, 0, :marker))
        |> Map.update!(next_pos_index, &Kernel.put_elem(&1, 0, :player))
        |> Map.put(:player, next_pos)
      {:ok, board}
    else
      _ -> :error
    end
  end
  def move_player(board, direction, _), do: move_player(board, direction)

  @doc """
  Returns the player's location in the board.

  ## Example:

      iex> alias Pathfinder.Board
      iex> {:ok, board} = Board.place_player(Board.new(), 1)
      iex> Board.player_location(board)
      {1, 1}

      iex> board = Pathfinder.Board.new()
      iex> Pathfinder.Board.player_location(board)
      nil

  """
  def player_location(board), do: Map.get(board, :player)

  @doc """
  Returns the goal's location in the board.

  ## Example:

      iex> alias Pathfinder.Board
      iex> {:ok, board} = Board.place_goal(Board.new(), {3, 4})
      iex> Board.goal_location(board)
      {3, 4}

      iex> board = Pathfinder.Board.new()
      iex> Pathfinder.Board.goal_location(board)
      nil

  """
  def goal_location(board), do: Map.get(board, :goal)

  @doc """
  Returns true if a goal exists and there exists a
  possible path to the goal.
  """
  def valid?(board) do
    if position = Map.get(board, :goal) do
      queue = :queue.in(position, :queue.new())
      discovered = Map.put(%{}, index(position), true)
      _validate_goal(board, queue, discovered)
    else
      false
    end
  end

  defp _validate_goal(board, queue, discovered) do
    {value, queue} = :queue.out(queue)
    case value do
      :empty ->
        false
      {:value, {_, col} = pos} ->
        case Map.get(board, index(pos)) do
          {_, _, _, _, left} when col == 1 and not left ->
            true
          nil ->
            false
          cell ->
            {queue, discovered} =
              _add_next_positions(pos, cell, queue, discovered)

            _validate_goal(board, queue, discovered)
        end
    end
  end

  defp _add_next_positions(pos, cell, queue, discovered) do
    filter_pos = fn
      {:ok, pos} -> not Map.has_key?(discovered, index(pos))
      _ -> false
    end

    next_positions =
      @directions
      |> Stream.filter_map(&(not elem(cell, &1)), &next(pos, &1))
      |> Stream.filter_map(filter_pos, fn {:ok, pos} -> pos end)

    Enum.reduce(next_positions, {queue, discovered}, fn pos, {queue, discovered} ->
      {:queue.in(pos, queue), Map.put(discovered, index(pos), true)}
    end)
  end
end
