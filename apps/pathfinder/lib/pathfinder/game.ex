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

  defstruct [
    state: {:build, nil},
    players: %{0 => %Player{}, 1 => %Player{}},
  ]

  def new do
    %Game{}
  end

  @doc """
  Handles a player's build request.

  Returns:
  {:ok, game} if the changes result in a valid grid.
  :error if there is a problem with the changes (the grid is invalid).
  """
  def build(%Game{state: {:build, nil}} = game, player, changes) do
    with {:ok, game} <- _build(game, player, changes),
         do: {:ok, %{game | state: {:build, player}}}
  end
  def build(%Game{state: {:build, i}} = game, player, changes) when i == 0 or i == 1 and i != player do
    with {:ok, game} <- _build(game, player, changes),
         do: {:ok, %{game | state: {:turn, 0}}}
  end

  @doc """
  Handles a player's action for a turn.

  Returns:
  {:win, player, game} if the player won from the action
  {:ok, game} if the player successfully completed the action
  :error if there was a problem completing the action
  """
  def turn(%Game{state: {:turn, i}} = game, player, {fun, args}) when i == player and fun in @allowed_turn_actions do
    board = get_in(game, [:players, player, :board])
    with {:ok, board} <- Kernel.apply(Board, fun, [board | args]) do
      # TODO(DarinM223): check for win condition
      game = update_in(game.players[player].board, fn _ -> board end)
      {:ok, game}
    else
      _ -> :error
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
      |> Stream.filter(fn {fun, args} -> fun in @allowed_build_actions end)
      |> Enum.reduce({:ok, board}, acc_changes)

    with {:ok, board} <- result,
         true <- Board.valid?(board) do
      game = update_in(game.players[player].board, fn _ -> board end)
      {:ok, game}
    else
      _ -> :error
    end
  end
end
