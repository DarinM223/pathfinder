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
import 'phoenix_html'
import 'jquery'

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

global.jQuery = require('jquery');
global.bootstrap = require('bootstrap');

import React, { Component, PropTypes } from 'react';
import ReactDOM from 'react-dom';
import { observer } from 'mobx-react';
import { Game, GameView } from './game.js';
import socket from './socket.js';

const game = new Game(socket, document.getElementById('game'));

ReactDOM.render(
  <GameView game={game} />,
  document.getElementById('game')
);
