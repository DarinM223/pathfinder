import React, { Component } from 'react';
import { observable, observer } from 'mobx-react';
import { Board } from './board/data.js';

class Game {
  @observable board;

  constructor(socket) {
    this.socket = socket;
    this.board = new Board(socket);

    // TODO(DarinM223): set up socket receive calls.
  }
}

@observer
class GameView extends Component {
  constructor(socket) {
    this.socket = socket;
  }
}
