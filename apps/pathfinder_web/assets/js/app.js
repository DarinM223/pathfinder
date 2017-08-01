// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"

import React, { Component, PropTypes } from 'react';
import ReactDOM from 'react-dom';
import { observer } from 'mobx-react';
import BoardStore, {
  Cell,
  MOVE_PLAYER,
  PLACE_WALL,
  PLACE_PLAYER,
  PLACE_GOAL
} from './board/data.js';
import {BoardView} from './board/view.js';

BoardStore.placePlayer(1);
BoardStore.transition(MOVE_PLAYER);

setTimeout(() => {
  BoardStore.toggleRowWall(2);
  BoardStore.toggleWall(3, 4, 3);
  BoardStore.placeGoal(3, 4);
  BoardStore.transition(PLACE_PLAYER);
}, 1000);

setTimeout(() => {
  BoardStore.transition(PLACE_GOAL);
}, 2000);

@observer
class GameView extends Component {
  render() {
    const store = this.props.store;
    let buttonControl = null;
    let stateText = '';
    switch (store.state.type) {
      case PLACE_GOAL:
        stateText = 'Currently placing goal';
        buttonControl = (
          <button onClick={e => store.transition(PLACE_WALL)}>
            Place walls
          </button>
        );
        break;
      case PLACE_WALL:
        stateText = 'Currently placing walls';
        buttonControl = (
          <button onClick={e => store.transition(PLACE_GOAL)}>
            Place goal
          </button>
        );
        break;
    }
    return (
      <div>
        <h2>{stateText}</h2>
        {buttonControl}
        <BoardView board={store} />
      </div>
    );
  }
}

ReactDOM.render(
  <GameView store={BoardStore} />,
  document.getElementById('game')
);
