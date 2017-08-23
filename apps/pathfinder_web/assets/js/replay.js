import React, { Component } from 'react';
import { action, observable } from 'mobx';
import { observer } from 'mobx-react';
import { BoardView } from './board/view.js';
import {
  Board,
  LEFT,
  PLACE_WALL,
  PLACE_GOAL,
  MOVE_PLAYER,
  PLACE_PLAYER,
  NO_STATE,
  WON_STATE,
  next,
  storageId
} from './board/data.js';

const BUILD_CHANGES = [
  'set_wall',
  'place_goal'
];

export class Replay {
  @observable playerBoard = new Board();
  @observable enemyBoard = new Board();
  @observable won = null;

  constructor(playerId, changes) {
    this.playerId = playerId;
    this.changes = changes;
    this.currentChange = -1;

    this.applyBuildChanges();
  }

  @action applyBuildChanges() {
    let i = 0;
    while (i < this.changes.length) {
      const change = this.changes[i];
      if (BUILD_CHANGES.indexOf(change.name) < 0) {
        break;
      }

      if (change.user_id == this.playerId) {
        this.playerBoard.applyAction(change);
      } else {
        this.enemyBoard.applyAction(change);
      }
      i++;
    }

    this.changes = this.changes.splice(i, this.changes.length);
  }

  @action next() {
    if (this.currentChange < this.changes.length - 1) {
      this.currentChange++;
      const change = this.changes[this.currentChange];
      if (change.user_id == this.playerId) {
        this.enemyBoard.applyAction(change);
      } else {
        this.playerBoard.applyAction(change);
      }
    }
  }

  @action prev() {
    if (this.currentChange > -1) {
      const change = this.changes[this.currentChange];
      if (change.user_id == this.playerId) {
        this.enemyBoard.undoAction(change);
      } else {
        this.playerBoard.undoAction(change);
      }
      this.currentChange--;
    }
  }
}

export class ReplayView extends Component {
  render() {
    const replay = this.props.replay;
    return (
      <div>
        <div className="container center-block">
          <div className="row">
            <div className="col-md-2" />
            <div className="col-md-4">
              <h3>Your board</h3>
              <BoardView board={replay.playerBoard} gameId={null} />
            </div>
            <div className="col-md-4">
              <h3>{"Other player's board"}</h3>
              <BoardView board={replay.enemyBoard} game={null} />
            </div>
            <div className="col-md-2" />
          </div>
          <br />
          <div className="row">
            <div className="col-md-5" />
            <div className="col-md-2">
              <button
                type="button"
                className="btn btn-info"
                onClick={e => replay.prev()}>
                {"< Prev"}
              </button>
              <button
                type="button"
                className="btn btn-info"
                onClick={e => replay.next()}>
                {"Next >"}
              </button>
            </div>
            <div className="col-md-5" />
          </div>
        </div>
      </div>
    );
  }
}
