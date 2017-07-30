import {action, observable, computed} from 'mobx';

export const TOP = 0;
export const RIGHT = 1;
export const BOTTOM = 2;
export const LEFT = 3;

export class Cell {
  @observable data = null;
  @observable walls = [false, false, false, false];

  constructor() {}
}

export class Board {
  @observable cells = makeCells();
  @observable player = null;

  @action toggleWall(row, col, direction) {
    this.cells[row][col].walls[direction] =
      !this.cells[row][col].walls[direction];

    const [nextRow, nextCol] = next(row, col, direction);
    const reversedDirection = reverse(direction);
    this.cells[nextRow][nextCol].walls[reversedDirection] =
      !this.cells[nextRow][nextCol].walls[reversedDirection];
  }

  @action toggleRowWall(row) {
    this.cells[row][0].walls[LEFT] =
      !this.cells[row][0].walls[LEFT];
  }

  @action placePlayer(row) {
    this.cells[row][0].data = 'player';
    this.player = [row, 0];
  }

  @action movePlayer(direction) {
    const [row, col] = this.player;
    this.player = next(row, col, direction);
  }
}

function next(row, col, direction) {
  switch (direction) {
    case TOP:
      return [row - 1, col];
    case RIGHT:
      return [row, col + 1];
    case BOTTOM:
      return [row + 1, col];
    case LEFT:
      return [row, col - 1];
  }
}

function reverse(direction) {
  switch (direction) {
    case TOP:
      return BOTTOM;
    case RIGHT:
      return LEFT;
    case BOTTOM:
      return TOP;
    case LEFT:
      return RIGHT;
  }
}

function makeCells() {
  let cells = [];
  for (let i = 0; i < 6; i++) {
    let row = [];
    for (let j = 0; j < 6; j++) {
      row.push(new Cell());
    }

    cells.push(row);
  }

  for (let col = 0; col < 6; col++) {
    cells[0][col].walls[TOP] = true;
    cells[cells.length - 1][col].walls[BOTTOM] = true;
  }
  for (let row = 0; row < 6; row++) {
    cells[row][cells[row].length - 1].walls[RIGHT] = true;
  }
  return cells;
}

const store = new Board();
export default store;
