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
import 'phoenix_html';
import 'jquery';
import 'bootstrap';

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// global.jQuery = require('jquery');
// global.bootstrap = require('bootstrap');

import React from 'react';
import ReactDOM from 'react-dom/client';
import { Game, GameView } from './game.jsx';
import { Replay, ReplayView } from './replay.tsx';
import socket from './socket.js';

const element = document.getElementById('game');
if (element !== null) {
  const game = new Game(socket, element);
  const replays = element.getAttribute('data-replay');
  const root = ReactDOM.createRoot(document.getElementById('game'));
  if (replays === null) {
    root.render(
      <React.StrictMode>
        <GameView game={game} />
      </React.StrictMode>
    );
  } else {
    const changes = JSON.parse(replays);
    const playerId = element.getAttribute('data-playerid');
    const replay = new Replay(playerId, changes);
    root.render(
      <React.StrictMode>
        <ReplayView replay={replay} />
      </React.StrictMode>
    );
  }
}
