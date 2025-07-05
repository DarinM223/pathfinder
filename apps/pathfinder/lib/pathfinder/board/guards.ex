defmodule Pathfinder.Board.Guards do
  @row_size Application.compile_env(:pathfinder, :row_size)
  @column_size Application.compile_env(:pathfinder, :column_size)

  defguard is_left_col(col) when col == 1
  defguard is_wall(cell, dir) when elem(cell, dir)
  defguard no_wall(cell, dir) when not elem(cell, dir)

  defguard validate_position(row, col)
           when row > 0 and row <= @column_size and col > 0 and col <= @row_size
end
