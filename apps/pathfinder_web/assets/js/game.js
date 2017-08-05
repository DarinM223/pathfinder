import React, { Component } from 'react';
import { action, observable } from 'mobx';
import { observer } from 'mobx-react';
import {
  Board,
  LEFT,
  PLACE_WALL,
  PLACE_GOAL,
  MOVE_PLAYER,
  PLACE_PLAYER,
  NO_STATE
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
    this.playerId = element.getAttribute('data-playerid');

    this.socket.connect();

    this.ready();
  }

  ready() {
    this.gamesChannel = this.socket.channel(`games:${this.gameId}`);

    this.gamesChannel.on('next', ({ changes, state }) => {
      if (changes.length > 0 && state.length === 2) {
        for (const change of changes) {
          if (state[1] == this.playerId) {
            this.playerBoard.applyAction(change);
          } else {
            this.enemyBoard.applyAction(change);
          }
        }
      }
      this.onNextState(state);
    });
    this.gamesChannel.join()
      .receive('ok', (player) => {
        console.log('Join succeeded with player: ', player);
        if (player !== null) {
          this.playerBoard.loadFromBackend(player.board);
          this.enemyBoard.loadFromBackend(player.enemy_board);

          this.onNextState(player.state);
        } else {
          this.playerBoard.transition(PLACE_WALL);
        }
      })
      .receive('error', (reason) => console.log('join failed', reason));
  }

  @action onNextState(state) {
    console.log('onNextState: ', state);
    if (state[0] === 'build') {
      this.playerBoard.transition(PLACE_WALL);
    } else if (state[0] === 'turn' && state[1] == this.playerId) {
      if (this.enemyBoard.player === null) {
        this.enemyBoard.transition(PLACE_PLAYER);
      } else {
        this.enemyBoard.transition(MOVE_PLAYER);
      }
    } else {
      this.playerBoard.transition(NO_STATE);
      this.enemyBoard.transition(NO_STATE);
    }
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

    this.gamesChannel
      .push('build', payload)
      .receive('ok', () => { this.error = ''; })
      .receive('error', () => { this.error = 'Error validating board'; });
  }

  @action movePlayer(direction) {
    console.log('movePlayer');
  }

  @action placePlayer(row) {
    const payload = {
      action: {
        name: 'place_player',
        params: [row + 1],
      }
    };

    this.gamesChannel
      .push('turn', payload)
      .receive('ok', () => { this.error = ''; })
      .receive('error', () => {
        this.enemyBoard.cells[row][0].walls[LEFT] = true;
      });
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
        <BoardView board={playerBoard} />
        <BoardView board={game.enemyBoard}
          movePlayer={direction => game.movePlayer(direction)}
          placePlayer={row => game.placePlayer(row)}
        />
      </div>
    );
  }
}
