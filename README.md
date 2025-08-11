# Pathfinder

A web application for the 1977 Milton Bradley board game where both players construct a maze
and the first player to navigate through the other players maze and reach
the goal is the winner.

Features:
---------

  * Create accounts which allow users to manage their active games.
  * Start games with other registered users, non-registered users through
    a one-time share link, and bots.
  * Both player's boards are validated so that they have a reachable goal before
    a game can start.
  * Simple UI for building mazes and playing the game. Walls are built by
    clicking two adjacent cells, and possible choices to move the player are
    highlighted. Move attempts by the opposite player are temporarily
    highlighted on your board.
  * View replays of past games played on your account. Replay pages show
    both player's full boards and support forward and backward
    stepping for every move in the game.


![pathfinder](./images/pathfinder.png)

Building mazes:

![building](./images/building.gif)

Gameplay from the perspective of both players:

![playing](./images/play.gif)

Replay view after a game has finished:

![replay](./images/replay.gif)