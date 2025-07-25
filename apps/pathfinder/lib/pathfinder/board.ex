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

  alias Pathfinder.Board
  alias Pathfinder.Board.Walls
  import Pathfinder.Board.Guards

  @row_size Application.compile_env(:pathfinder, :row_size)
  @column_size Application.compile_env(:pathfinder, :column_size)
  @directions [
    # Top
    1,
    # Right
    2,
    # Bottom
    3,
    # Left
    4
  ]

  @doc """
  Creates an empty board.

      iex> board = Pathfinder.Board.new()
      iex> board |> Map.keys() |> length == (36 + 2)
      true

  """
  def new do
    for(
      row <- 1..@column_size,
      col <- 1..@row_size,
      do: {row, col}
    )
    |> Stream.map(&initial_cell/1)
    |> init_board()
  end

  defp initial_cell({1, @row_size}), do: {nil, true, true, false, false}
  defp initial_cell({@column_size, @row_size}), do: {nil, false, true, true, false}
  defp initial_cell({_, @row_size}), do: {nil, false, true, false, false}
  defp initial_cell({1, _}), do: {nil, true, false, false, false}
  defp initial_cell({@column_size, _}), do: {nil, false, false, true, false}
  defp initial_cell(_), do: {nil, false, false, false, false}

  # Converts a board to from a list of cells to a map of indexes to cells
  # and sets the player and goal to nil.
  defp init_board(cells) do
    cells
    |> Stream.with_index(0)
    |> Enum.reduce(%{}, fn {cell, index}, acc ->
      Map.put(acc, index, cell)
    end)
    |> Map.put(:player, nil)
    |> Map.put(:goal, nil)
  end

  @doc """
  Generates changes that creates a board with a random maze.

  Uses the recursive backtracking algorithm described in:
  https://en.wikipedia.org/wiki/Maze_generation_algorithm
  """
  def generate_changes do
    entry_row = Enum.random(1..@column_size)

    Walls.set_all(@row_size, @column_size)
    |> Walls.remove_random({entry_row, 1})
    |> Walls.add_random_row_walls(@column_size, entry_row)
    |> Walls.to_change_list()
    |> add_goal()
    |> Enum.reverse()
  end

  defp add_goal(changes) do
    # Try to pick a random goal with three walls.
    possible_goals =
      Enum.reduce(changes, %{}, fn
        {:set_wall, [pos, _, true]}, map ->
          Map.update(map, pos, initial_walls(pos) + 1, &(&1 + 1))

        {:set_wall, [row, true]}, map ->
          pos = {row, 1}
          Map.update(map, pos, initial_walls(pos) + 1, &(&1 + 1))
      end)
      |> Enum.filter(fn {_, num_walls} -> num_walls >= 3 end)
      |> Enum.map(&elem(&1, 0))

    goal_pos =
      if not Enum.empty?(possible_goals) do
        Enum.random(possible_goals)
      else
        {Enum.random(1..@column_size), Enum.random(1..@row_size)}
      end

    [{:place_goal, [goal_pos]} | changes]
  end

  defp initial_walls({1, @row_size}), do: 2
  defp initial_walls({@column_size, @row_size}), do: 2
  defp initial_walls({1, _}), do: 1
  defp initial_walls({@column_size, _}), do: 1
  defp initial_walls({_, @row_size}), do: 1
  defp initial_walls(_), do: 0

  @doc """
  Applies a list of changes to the board.

      iex> {:ok, board} = Pathfinder.Board.apply_changes(Pathfinder.Board.new(), [{:set_wall, [{1, 1}, {1, 2}, true]}])
      iex> Map.get(board, Pathfinder.Board.index({1, 1})) # Check that wall was set
      {nil, true, true, false, false}

      iex> Pathfinder.Board.apply_changes(Pathfinder.Board.new(), [{:set_wall, [{1, 1}, {1, 0}, true]}])
      :error

  """
  def apply_changes(board, changes) do
    Enum.reduce(changes, {:ok, board}, fn
      {fun, args}, {:ok, board} -> Kernel.apply(Board, fun, [board | args])
      _, err -> err
    end)
  end

  @doc """
  Creates a board with a random maze.
  """
  def generate do
    {:ok, board} = apply_changes(Board.new(), generate_changes())
    board
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
    |> Stream.filter(fn
      {_, {:ok, _}} -> true
      _ -> false
    end)
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
      _ -> raise "Invalid direction: #{inspect(direction)}"
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
        _ -> raise "Invalid direction: #{inspect(direction)}"
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
    with {row, col} when is_left_col(col) <- Map.get(board, :player),
         pos_index <- index(row, col),
         {:ok, cell} when no_wall(cell, 4) <- Map.fetch(board, pos_index) do
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
      {:ok, cell} when no_wall(cell, direction) -> true
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
         {:ok, cell} when no_wall(cell, direction) <- Map.fetch(board, pos_index) do
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
      validate_goal(board, queue, discovered)
    else
      false
    end
  end

  defp validate_goal(board, queue, discovered) do
    {value, queue} = :queue.out(queue)

    case value do
      :empty ->
        false

      {:value, {_, col} = pos} ->
        case Map.get(board, index(pos)) do
          {_, _, _, _, left} when is_left_col(col) and not left ->
            true

          nil ->
            false

          cell ->
            {queue, discovered} = add_next_positions(pos, cell, queue, discovered)

            validate_goal(board, queue, discovered)
        end
    end
  end

  defp add_next_positions(pos, cell, queue, discovered) do
    filter_pos = fn
      {:ok, pos} -> not Map.has_key?(discovered, index(pos))
      _ -> false
    end

    next_positions =
      @directions
      |> Stream.filter(&(not elem(cell, &1)))
      |> Stream.map(&next(pos, &1))
      |> Stream.filter(filter_pos)
      |> Stream.map(fn {:ok, pos} -> pos end)

    Enum.reduce(next_positions, {queue, discovered}, fn pos, {queue, discovered} ->
      {:queue.in(pos, queue), Map.put(discovered, index(pos), true)}
    end)
  end
end
