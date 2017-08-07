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
  NO_STATE,
  next
} from './board/data.js';
import { BoardView } from './board/view.js';
import CopyToClipboard from 'react-copy-to-clipboard';

export class Game {
  @observable playerBoard;
  @observable enemyBoard;
  @observable error = null;
  @observable won = null;

  constructor(socket, element) {
    this.socket = socket;
    this.playerBoard = new Board();
    this.enemyBoard = new Board();
    this.gameId = element.getAttribute('data-id');
    this.playerId = element.getAttribute('data-playerid');
    this.shareId = element.getAttribute('data-shareid');

    this.socket.connect();

    this.ready();
  }

  ready() {
    this.gamesChannel = this.socket.channel(`games:${this.gameId}`);

    this.gamesChannel.on('next', ({ changes, state }) => {
      if (changes.length > 0 && state.length === 2) {
        for (const change of changes) {
          switch (state[0]) {
            case 'win':
              if (state[1] == this.playerId) {
                this.enemyBoard.applyAction(change);
              } else {
                this.playerBoard.applyAction(change);
              }
              break;
            case 'turn':
              if (state[1] == this.playerId) {
                this.playerBoard.applyAction(change);
              } else {
                this.enemyBoard.applyAction(change);
              }
              break;
          }
        }
      }
      this.onNextState(state);
    });

    this.gamesChannel.join()
      .receive('ok', (player) => {
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
    if (state[0] === 'build') {
      this.playerBoard.transition(PLACE_WALL);
    } else if (state[0] === 'win') {
      if (state[1] == this.playerId) {
        this.won = true;
      } else {
        this.won = false;
      }
      this.playerBoard.transition(NO_STATE);
      this.enemyBoard.transition(NO_STATE);
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
    const payload = {
      action: {
        name: 'move_player',
        params: [direction + 1],
      }
    };

    this.gamesChannel
      .push('turn', payload)
      .receive('ok', () => { this.error = ''; })
      .receive('error', () => {
        const [playerRow, playerCol] = this.enemyBoard.player;
        this.enemyBoard.setWall(playerRow, playerCol, direction);
      });
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

  @action removePlayer(row) {
    const payload = {
      action: {
        name: 'remove_player',
        params: [],
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

const buttonStyle = {
  marginLeft: '10px',
  marginRight: '5px'
};

@observer
export class GameView extends Component {
  render() {
    const game = this.props.game;

    const playerBoard = game.playerBoard;
    let switchButton = null;
    let buildButton = (
      <button className="btn btn-success" onClick={e => game.build()}>
        Validate
      </button>
    );
    let stateText = '';
    switch (playerBoard.state.type) {
      case PLACE_GOAL:
        stateText = 'Currently placing goal';
        switchButton = (
          <button
            style={buttonStyle}
            className="btn btn-info"
            onClick={e => playerBoard.transition(PLACE_WALL)}>
            Placing goal
          </button>
        );
        break;
      case PLACE_WALL:
        stateText = 'Currently placing walls';
        switchButton = (
          <button
            style={buttonStyle}
            className="btn btn-info"
            onClick={e => playerBoard.transition(PLACE_GOAL)}>
            Placing walls
          </button>
        );
        break;
      default:
        buildButton = null;
        break;
    }

    if (game.won === true) {
      stateText = 'You won! :)';
    } else if (game.won === false) {
      stateText = 'You lost! :(';
    }

    let errorText = null;
    if (game.error !== null && game.error.length > 0) {
      errorText = <div className="alert alert-danger" role="alert">{game.error}</div>;
    }

    return (
      <div>
        {errorText}
        <div className="container center-block">
          <div className="row">
            <div className="col-md-2" />
            <div className="col-md-4">
              <h3>Your board</h3>
              <BoardView board={playerBoard} />
              <br />
              {switchButton}
              {buildButton}
            </div>
            <div className="col-md-4">
              <h3>Other player's board</h3>
              <BoardView board={game.enemyBoard}
                movePlayer={direction => game.movePlayer(direction)}
                placePlayer={row => game.placePlayer(row)}
                removePlayer={row => game.removePlayer(row)}
              />
              <br />
              <CopyToClipboard text={game.shareId}>
                <button style={buttonStyle} className="btn btn-info">Copy share url</button>
              </CopyToClipboard>
            </div>
            <div className="col-md-2" />
          </div>
        </div>
      </div>
    );
  }
}
