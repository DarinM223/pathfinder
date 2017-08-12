import React, { Component } from 'react';
import { observer } from 'mobx-react';
import {
  PLACE_WALL,
  PLACE_GOAL,
  MOVE_PLAYER,
  PLACE_PLAYER,
  NO_STATE
} from './board/data.js';

const styles = {
  centerText: {
    textAlign: 'center'
  },
  centerList: {
    display: "inline-block"
  }
};

const PLACE_WALL_TEXT = (
  <div>
    <h2 style={styles.centerText}>Building Maze</h2>
    <div style={styles.centerText}>
      <ul style={styles.centerList}>
        <li style={styles.listItem}>Click on two adjacent cells to place/remove a wall between them.</li>
        <li style={styles.listItem}>Double-click a cell in the first column to place/remove a row wall.</li>
        <li style={styles.listItem}>{"Click the 'Place goal' button to switch to placing the goal."}</li>
        <li style={styles.listItem}>{"Click the 'Clear board' button to reset the board."}</li>
        <li style={styles.listItem}>{"Click the 'Validate' button when you are finished making the maze."}</li>
      </ul>
    </div>
  </div>
);
const PLACE_GOAL_TEXT = (
  <div>
    <h2 style={styles.centerText}>Building Maze</h2>
    <div style={styles.centerText}>
      <ul style={styles.centerList}>
        <li style={styles.listItem}>Click on a cell in the board to place the goal on the cell.</li>
        <li style={styles.listItem}>{"Click the 'Place walls' button to switch to placing the walls."}</li>
        <li style={styles.listItem}>{"Click the 'Clear board' button to reset the board."}</li>
        <li style={styles.listItem}>{"Click the 'Validate' when you are finished making the maze."}</li>
      </ul>
    </div>
  </div>
);
const MOVE_PLAYER_TEXT = (
  <div>
    <h2 style={styles.centerText}>Your Turn</h2>
    <div style={styles.centerText}>
      <ul style={styles.centerList}>
        <li style={styles.listItem}>Click on one of the highlighted cells adjacent to the player to attempt to move there.</li>
        <li style={styles.listItem}>{"If the player is on the first column, clicking the player's cell will attempt to move out of the board."}</li>
      </ul>
    </div>
  </div>
);
const PLACE_PLAYER_TEXT = (
  <div>
    <h2 style={styles.centerText}>Your Turn</h2>
    <div style={styles.centerText}>
      <ul style={styles.centerList}>
        <li style={styles.listItem}>Click on one of the highlighted cells to attempt to place the player there.</li>
      </ul>
    </div>
  </div>
);
const WAITING_TEXT = (
  <h2 style={styles.centerText}>Waiting for other player...</h2>
);
const WON_TEXT = (
  <div>
    <h2 style={styles.centerText}>{"You won!"}</h2>
  </div>
);
const LOSE_TEXT = (
  <div>
    <h2 style={styles.centerText}>{"You lost!"}</h2>
  </div>
);
const errorAlert = (error) => (
  <div className="alert alert-danger" style={styles.centerText} role="alert">
    {error}
  </div>
);

@observer
export class GameTextView extends Component {
  render() {
    const game = this.props.game;
    let text = null;
    let alert = null;

    switch (game.playerBoard.state.type) {
      case PLACE_GOAL:
        text = PLACE_GOAL_TEXT;
        break;
      case PLACE_WALL:
        text = PLACE_WALL_TEXT;
        break;
    }
    switch (game.enemyBoard.state.type) {
      case MOVE_PLAYER:
        text = MOVE_PLAYER_TEXT;
        break;
      case PLACE_PLAYER:
        text = PLACE_PLAYER_TEXT;
        break;
    }
    if (game.enemyBoard.state.type === NO_STATE &&
        game.playerBoard.state.type === NO_STATE &&
        game.won === null) {
      text = WAITING_TEXT;
    }

    switch (game.won) {
      case true:
        text = WON_TEXT;
        break;
      case false:
        text = LOSE_TEXT;
        break;
    }
    if (game.error !== null && game.error.length > 0) {
      alert = errorAlert(game.error);
    }

    return (
      <div>
        {alert}
        {text}
      </div>
    );
  }
}
