import React, { Component } from 'react';
import { action, observable } from 'mobx';
import { observer } from 'mobx-react';
import {
  Board,
  PLACE_WALL,
  PLACE_GOAL
} from './board/data.js';
import { BoardView } from './board/view.js';

export class Game {
  @observable playerBoard;
  @observable enemyBoard;

  constructor(socket, element) {
    this.socket = socket;
    this.playerBoard = new Board();
    this.enemyBoard = new Board();
    this.gameId = element.getAttribute('data-id');

    this.socket.connect();

    this.ready();
  }

  ready() {
    const gamesChannel = this.socket.channel(`games:${this.gameId}`);

    gamesChannel.on('turn', ({ playerId, action, success }) => {
      // TODO(DarinM223): apply player action on the correct player board.
      // TODO(DarinM223): if the player id is different, transition to move player state.
    });

    console.log('Games channel: ', gamesChannel);

    gamesChannel.join()
      .receive('ok', (player) => {
        console.log('Join succeeded with player: ', player);
        if (player !== null) {
          this.playerBoard.loadFromBackend(player.board);
          this.enemyBoard.loadFromBackend(player.enemy_board);

          if (player.state[0] === 'build') {
            this.playerBoard.transition(PLACE_WALL);
          } else if (player.state[0] === 'turn' && player.state[1] === player.id) {
            this.playerBoard.transition(MOVE_PLAYER);
          } else {
            this.playerBoard.transition(NO_STATE);
          }
        } else {
          this.playerBoard.transition(PLACE_WALL);
        }
      })
      .receive('error', (reason) => console.log('join failed', reason));
  }

  // TODO(DarinM223): send websocket messages for build(), movePlayer(), and placePlayer().

  @action build() {
  }

  @action movePlayer(row, col, direction) {
  }

  @action placePlayer(row) {
  }
}

@observer
export class GameView extends Component {
  render() {
    const game = this.props.game;

    const playerBoard = game.playerBoard;
    let buttonControl = null;
    let stateText = '';
    switch (playerBoard.state.type) {
      case PLACE_GOAL:
        stateText = 'Currently placing goal';
        buttonControl = (
          <button onClick={e => playerBoard.transition(PLACE_WALL)}>
            Place walls
          </button>
        );
        break;
      case PLACE_WALL:
        stateText = 'Currently placing walls';
        buttonControl = (
          <button onClick={e => playerBoard.transition(PLACE_GOAL)}>
            Place goal
          </button>
        );
        break;
    }

    return (
      <div>
        <h2>{stateText}</h2>
        {buttonControl}
        <BoardView
          board={playerBoard}
          movePlayer={playerBoard.movePlayer.bind(playerBoard)}
          placePlayer={playerBoard.placePlayer.bind(playerBoard)}
        />
        <BoardView board={game.enemyBoard} />
      </div>
    );
  }
}
