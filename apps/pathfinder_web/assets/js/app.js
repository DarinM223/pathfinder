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
import {observable, computed} from 'mobx';
import {observer} from 'mobx-react';
import BoardStore, {Cell} from './board/data.js';
import {BoardView} from './board/view.js';

BoardStore.placePlayer(1);

setTimeout(() => {
  BoardStore.movePlayer(2);
  BoardStore.toggleRowWall(2);
  BoardStore.toggleWall(3, 4, 3);
  BoardStore.placeGoal(3, 4);
}, 1000);

BoardStore.state = { type: 'PLACE_WALL', firstCell: null };

ReactDOM.render(
  <BoardView board={BoardStore} />,
  document.getElementById('game')
);
