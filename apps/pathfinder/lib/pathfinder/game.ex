defmodule Pathfinder.Game do
  @moduledoc """
  Stores the data for a pathfinder game.

  The game can be in three states:
  1. {:build, player} -> board building state
     if player is nil, no player has finished
     if player is a player index, one player has finished
  2. {:turn, player} -> a certain player's turn
  3. {:win, player} -> a certain player won
  """

  alias Pathfinder.Board
  alias Pathfinder.Player
  alias Pathfinder.Game

  @allowed_build_actions [:place_goal, :set_wall]
  @allowed_turn_actions [:place_player, :remove_player, :move_player]

  @doc """
  Returns a new game state.
  """
  def new do
    %{state: {:build, nil},
      players: %{0 => Player.new(),
                 1 => Player.new()}}
  end

  @doc """
  Returns the console printable version of the game as an IO list.
  """
  def to_io_list(game) do
    ["Player 1:\n",
     Player.to_io_list(get_in(game, [:players, 0])),
     "Player 2:\n",
     Player.to_io_list(get_in(game, [:players, 1]))]
  end

  @doc """
  Returns the current state of the game.
  """
  def state(%{state: state}), do: state

  @doc """
  Handles a player's build request.

  Returns:
  {:turn, player, game} if both players built their grids
  {:ok, game} if not all players have build their grids
  :error if there is a problem with the changes (the grid is invalid).
  """
  def build(%{state: {:build, nil}} = game, player, changes) do
    with {:ok, game} <- _build(game, player, changes) do
      {:ok, %{game | state: {:build, player}}}
    end
  end
  def build(%{state: {:build, i}} = game, player, changes)
      when (i == 0 or i == 1) and i != player do

    next_player = Enum.random(0..1)
    with {:ok, game} <- _build(game, player, changes) do
      {:turn, next_player, %{game | state: {:turn, next_player}}}
    end
  end

  defp _build(game, player, changes) do
    board = get_in(game, [:players, player, :board])

    acc_changes = fn
      {fun, args}, {:ok, board} ->
        Kernel.apply(Board, fun, [board | args])
      _, error ->
        error
    end

    result =
      changes
      |> Stream.filter(fn {fun, _} -> fun in @allowed_build_actions end)
      |> Enum.reduce({:ok, board}, acc_changes)

    with {:ok, board} <- result,
         true <- Board.valid?(board) do
      game = update_in(game.players[player].board, fn _ -> board end)
      {:ok, game}
    else
      _ -> :error
    end
  end

  @doc """
  Handles a player's action for a turn.

  Returns:
  {:win, player, game} if the player won from the action
  {:turn, player, game} for the next player's turn
  {:error, player, game} if there was a problem completing the action
  """
  def turn(%{state: {:turn, i}} = game, player, {fun, args})
      when (i == 0 or i == 1) and
           i == player and
           fun in @allowed_turn_actions do

    enemy = if player == 0, do: 1, else: 0
    game = %{game | state: {:turn, enemy}}
    enemy_board = get_in(game, [:players, enemy, :board])
    player_enemy_board = get_in(game, [:players, player, :enemy_board])

    with {:ok, enemy_board} <- Kernel.apply(Board, fun, [enemy_board | args]),
         {:ok, player_enemy_board} <- Kernel.apply(Board, fun, [player_enemy_board | args]) do
      game = update_in(game.players[enemy].board, fn _ -> enemy_board end)
      game = update_in(game.players[player].enemy_board, fn _ -> player_enemy_board end)

      if Game.won?(game, enemy) do
        {:win, player, game}
      else
        {:turn, enemy, game}
      end
    else
      _ ->
        game = handle_turn_error(fun, args, game, player)
        {:error, enemy, game}
    end
  end

  defp handle_turn_error(:place_player, args, game, player) do
    [row | _] = args
    update_in(game.players[player].enemy_board, fn board ->
      {:ok, board} = Board.set_wall(board, row, true)
      board
    end)
  end
  defp handle_turn_error(:remove_player, _, game, player) do
    board = get_in(game, [:players, player, :enemy_board])
    {row, _} = Board.player_location(board)
    update_in(game.players[player].enemy_board, fn board ->
      {:ok, board} = Board.set_wall(board, row, true)
      board
    end)
  end
  defp handle_turn_error(:move_player, args, game, player) do
    [direction | _] = args
    board = get_in(game, [:players, player, :enemy_board])
    pos1 = Board.player_location(board)
    {:ok, pos2} = Board.next(pos1, direction)
    update_in(game.players[player].enemy_board, fn board ->
      {:ok, board} = Board.set_wall(board, pos1, pos2, true)
      board
    end)
  end

  @doc """
  Returns true if the enemy's board has the player
  reach the goal.
  """
  def won?(game, enemy) do
    board = get_in(game, [:players, enemy, :board])
    player_location = Board.player_location(board)

    player_location != nil and player_location == Board.goal_location(board)
  end
end
