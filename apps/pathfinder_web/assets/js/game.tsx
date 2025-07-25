import React, { Component } from 'react';
import { action, observable } from 'mobx';
import { observer } from 'mobx-react';
import {
  Action,
  BackendBoard,
  Board,
  Direction,
  next,
  storageId
} from './board/data.ts';
import { BoardView } from './board/view.tsx';
import { GameTextView } from './text.tsx';
import {
  switchButton,
  boardStatus,
  shareButton,
  buildButton,
  clearButton,
  buildModal,
  clearModal
} from './controls.tsx';

type PlayerId = string
type BackendState = ['win', PlayerId] | ['turn', PlayerId] | ['build', PlayerId | null]

type BackendPlayer = {
  board: BackendBoard,
  enemy_board: BackendBoard,
  state: BackendState,
}

export class Game {
  @observable playerBoard: Board;
  @observable enemyBoard: Board;
  @observable error: string | null = null;
  @observable won: boolean | null = null;

  gameId: string
  playerId: PlayerId
  shareId: string
  replayLink: string

  socket: any
  gamesChannel: any

  constructor(socket: any, element: HTMLElement) {
    this.socket = socket;
    this.playerBoard = new Board();
    this.enemyBoard = new Board();
    this.gameId = element.getAttribute('data-id')!;
    this.playerId = element.getAttribute('data-playerid')!;
    this.shareId = element.getAttribute('data-shareid')!;
    this.replayLink = element.getAttribute('data-replaylink')!;

    this.socket.connect();

    this.ready();
  }

  ready() {
    this.gamesChannel = this.socket.channel(`games:${this.gameId}`);

    this.gamesChannel.on('next', ({ changes, state }: { changes: Action[], state: BackendState }) => {
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
      .receive('ok', (player: BackendPlayer) => {
        if (player !== null) {
          const board = JSON.parse(localStorage.getItem(storageId(this.gameId))!);
          if (player.state[0] === 'build' && typeof board !== 'undefined' && board !== null) {
            this.playerBoard.loadFromJSON(board);
          } else {
            this.playerBoard.loadFromBackend(player.board);
          }
          this.enemyBoard.loadFromBackend(player.enemy_board);

          this.onNextState(player.state);
        } else {
          this.playerBoard.transition('PLACE_WALL');
        }
      })
      .receive('error', (reason: any) => console.log('join failed', reason));
  }

  @action clear() {
    localStorage.removeItem(storageId(this.gameId));
    const state = this.playerBoard.state;
    this.playerBoard = new Board();
    this.playerBoard.state = state;
  }

  @action onNextState(state: BackendState) {
    if (state[0] === 'build') {
      if (state[1] === null || state[1] != this.playerId) {
        this.playerBoard.transition('PLACE_WALL');
      } else {
        this.playerBoard.transition('NO_STATE');
      }
    } else if (state[0] === 'win') {
      if (state[1] == this.playerId) {
        this.won = true;
        this.enemyBoard.transition('WON_STATE');
        this.playerBoard.transition('NO_STATE');
      } else {
        this.won = false;
        this.enemyBoard.transition('NO_STATE');
        this.playerBoard.transition('WON_STATE');
      }
    } else if (state[0] === 'turn' && state[1] == this.playerId) {
      if (this.enemyBoard.player === null) {
        this.enemyBoard.transition('PLACE_PLAYER');
      } else {
        this.enemyBoard.transition('MOVE_PLAYER');
      }
    } else {
      this.playerBoard.transition('NO_STATE');
      this.enemyBoard.transition('NO_STATE');
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
      .receive('ok', () => {
        this.error = '';
        this.playerBoard.transition('NO_STATE');
      })
      .receive('error', () => {
        this.error = `The maze is not valid; a valid maze has to have an
        unblocked path from the left side of the board to the goal.`;
      });
  }

  @action movePlayer(direction: Direction) {
    const [nextRow, nextCol] = next(...this.enemyBoard.player!, direction);
    const payload = {
      action: {
        name: 'move_player',
        params: [direction + 1, [nextRow + 1, nextCol + 1]],
      }
    };

    this.gamesChannel
      .push('turn', payload)
      .receive('ok', () => { this.error = ''; })
      .receive('error', () => {
        const [playerRow, playerCol] = this.enemyBoard.player!;
        this.enemyBoard.setWall(playerRow, playerCol, direction);
      });
  }

  @action placePlayer(row: number) {
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
        this.enemyBoard.cells[row][0].walls[Direction.Left] = true;
      });
  }

  @action removePlayer(row: number) {
    const payload = {
      action: {
        name: 'remove_player',
        params: [row + 1],
      }
    };

    this.gamesChannel
      .push('turn', payload)
      .receive('ok', () => { this.error = ''; })
      .receive('error', () => {
        this.enemyBoard.cells[row][0].walls[Direction.Left] = true;
      });
  }
}

type GameViewProps = {
  game: Game
}

@observer
export class GameView extends Component<GameViewProps, {}> {
  render() {
    const game = this.props.game;
    const playerBoard = game.playerBoard;

    return (
      <div>
        <div className="container center-block">
          <div className="row">
            <GameTextView game={game} />
          </div>
          <div className="row">
            <div className="col-md-2" />
            <div className="col-md-4">
              <h3>Your board {boardStatus(playerBoard)}</h3>
              <BoardView board={playerBoard} gameId={game.gameId} />
              <br />
              {switchButton(playerBoard)}
              {clearButton(playerBoard)}
              {buildButton(playerBoard)}
            </div>
            <div className="col-md-4">
              <h3>{"Other player's board"}</h3>
              <BoardView board={game.enemyBoard}
                movePlayer={direction => game.movePlayer(direction)}
                placePlayer={row => game.placePlayer(row)}
                removePlayer={row => game.removePlayer(row)}
                gameId={game.gameId}
              />
              <br />
              {shareButton(game)}
            </div>
            <div className="col-md-2" />
          </div>
          {buildModal(e => game.build())}
          {clearModal(e => game.clear())}
        </div>
      </div>
    );
  }
}
