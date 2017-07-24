defmodule Pathfinder.Worker do
  @moduledoc """
  A game worker that handles the state for
  a single pathfinder game.

  The game can be in three states:
  1. {:build, built_players} -> board building state
  2. {:turn, player} -> a certain player's turn
  3. {:win, player} -> a certain player won
  """

  use GenServer

  alias Pathfinder.Board

  @allowed_build_actions [:place_goal, :set_wall]

  def start_link(registry, store, id, opts \\ []) do
    name = {:via, Registry, {registry, id}}
    GenServer.start_link(__MODULE__, {store, id}, [{:name, name} | opts])
  end

  def init({store, id}) do
    if {game_state, players} = Pathfinder.Store.get(store, id) do
      {:ok, {game_state, players, {store, id}}}
    else
      player1 = {Board.new(), Board.new()}
      player2 = {Board.new(), Board.new()}
      game_state = {:build, 0}
      players = {player1, player2}

      Pathfinder.Store.set(store, id, {game_state, players})
      {:ok, {game_state, players, {store, id}}}
    end
  end

  def handle_call({:build, player, changes}, {{:build, count}, players, _} = state) do
    boards = {board, _} = elem(players, player)

    acc_changes = fn
      {fun, args}, {:ok, board} ->
        Kernel.apply(Board, fun, args)
      _, error ->
        error
    end

    result =
      changes
      |> Stream.filter(fn {fun, args} -> fun in @allowed_build_actions end)
      |> Enum.reduce({:ok, board}, acc_changes)

    with {:ok, board} <- result,
         true <- Board.valid?(board) do
      boards = Kernel.put_elem(boards, 0, board)
      players = Kernel.put_elem(players, player, boards)
      state = Kernel.put_elem(state, 1, players)

      {:reply, :ok, state}
    else
      _ -> {:reply, :error, state}
    end
  end
  def handle_call({:build, _, _}, state) do
    {:reply, :error, state}
  end

  def handle_call({:turn, player, action}, {{:turn, player}, players, _}) do
    # TODO(DarinM223):
  end
  def handle_call({:turn, _, _}, state) do
    {:reply, :error, state}
  end
end
