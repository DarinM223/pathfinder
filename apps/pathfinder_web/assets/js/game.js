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
  @observable error = null;

  constructor(socket, element) {
    this.socket = socket;
    this.playerBoard = new Board();
    this.enemyBoard = new Board();
    this.gameId = element.getAttribute('data-id');

    this.socket.connect();

    this.ready();
  }

  ready() {
    this.gamesChannel = this.socket.channel(`games:${this.gameId}`);

    this.gamesChannel.on('turn', ({ playerId, action, success }) => {
      // TODO(DarinM223): apply player action on the correct player board.
      // TODO(DarinM223): if the player id is different, transition to move player state.
    });

    this.gamesChannel.join()
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
    if (this.playerBoard.goal === null) {
      this.error = 'Goal must be set before validation';
      return;
    }
    const [goalRow, goalCol] = this.playerBoard.goal;
    const actions = this.playerBoard.setWallActions;
    actions.push({
      name: 'place_goal',
      params: [[goalRow + 1, goalCol + 1]],
    });
    const payload = { changes: actions };

    console.log('Build Payload: ', payload);

    this.gamesChannel
      .push('build', payload)
      .receive('ok', () => { this.error = ''; })
      .receive('error', () => { this.error = 'Error validating board'; });
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
    let switchButton = null;
    let buildButton = (
      <button onClick={e => game.build()}>
        Validate
      </button>
    );
    let stateText = '';
    switch (playerBoard.state.type) {
      case PLACE_GOAL:
        stateText = 'Currently placing goal';
        switchButton = (
          <button onClick={e => playerBoard.transition(PLACE_WALL)}>
            Place walls
          </button>
        );
        break;
      case PLACE_WALL:
        stateText = 'Currently placing walls';
        switchButton = (
          <button onClick={e => playerBoard.transition(PLACE_GOAL)}>
            Place goal
          </button>
        );
        break;
      default:
        buildButton = null;
        break;
    }

    return (
      <div>
        <h2>{stateText}</h2>
        <div className="alert alert-error">{game.error}</div>
        {switchButton}
        {buildButton}
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
