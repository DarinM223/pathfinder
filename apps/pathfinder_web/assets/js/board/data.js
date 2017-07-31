import {action, observable, computed} from 'mobx';

/*
 * Direction types.
 */
export const TOP = 0;
export const RIGHT = 1;
export const BOTTOM = 2;
export const LEFT = 3;

/*
 * Cell highlight types.
 */
export const SELECTED_HIGHLIGHT = 'INFO_HIGHLIGHT';
export const HINT_HIGHLIGHT = 'HINT_HIGHLIGHT';

export const PLAYER = 'PLAYER';
export const GOAL = 'GOAL';

export class Cell {
  @observable data = null;
  @observable walls = [false, false, false, false];
  @observable highlight = null;

  constructor() {}
}

/*
 * Valid board state types.
 */
export const NO_STATE = 'NO_STATE';
export const PLACE_WALL = 'PLACE_WALL';
export const PLACE_GOAL = 'PLACE_GOAL';
export const MOVE_PLAYER = 'MOVE_PLAYER';
export const PLACE_PLAYER = 'PLACE_PLAYER';

export class Board {
  @observable cells = makeCells();
  @observable player = null;
  @observable goal = null;
  /**
   * State can be in:
   *
   * No state:
   * { type: 'NO_STATE' }
   *
   * Place wall:
   * { type: 'PLACE_WALL', firstCell: null }
   *
   * Place goal:
   * { type: 'PLACE_GOAL' }
   *
   * Move player:
   * { type: 'MOVE_PLAYER' }
   *
   * Place player:
   * { type: 'PLACE_PLAYER' }
   */
  @observable state = { type: NO_STATE };

  @action onCellClick(row, col) {
    switch (this.state.type) {
      case PLACE_WALL:
        if (this.state.firstCell === null) {
          this.toggleHighlight(row, col);
          this.state.firstCell = [row, col];
          break;
        }

        // If the cell is clicked twice if the cell
        // is on the first column, set the row wall.
        if (this.state.firstCell[0] === row &&
            this.state.firstCell[1] === col &&
            col === 0) {
          this.toggleRowWall(row);
          this.resetPlaceWall();
          break;
        }

        // Otherwise set the wall between the two cells or
        // reset if the cells aren't adjacent to each other.
        const direction = directionBetweenCells(this.state.firstCell, [row, col]);
        if (direction === null) {
          this.resetPlaceWall();
          break;
        }

        this.toggleWall(this.state.firstCell[0], this.state.firstCell[1], direction);
        this.resetPlaceWall();
        break;
      case PLACE_GOAL:
        break;
      case MOVE_PLAYER:
        break;
      case PLACE_PLAYER:
        break;
    }
  }

  @action resetPlaceWall() {
    const [row, col] = this.state.firstCell;
    this.toggleHighlight(row, col);
    this.state.firstCell = null;
  }

  @action toggleHighlight(row, col) {
    this.cells[row][col].highlight =
      this.cells[row][col].highlight ? null : SELECTED_HIGHLIGHT;

    for (let direction = TOP; direction <= LEFT; direction++) {
      const [nextRow, nextCol] = next(row, col, direction);
      if (isValidCell(nextRow, nextCol)) {
        this.cells[nextRow][nextCol].highlight =
          this.cells[nextRow][nextCol].highlight ? null : HINT_HIGHLIGHT;
      }
    }
  }

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
    this.cells[row][0].data = PLAYER;
    this.player = [row, 0];
  }

  @action placeGoal(row, col) {
    this.cells[row][col].data = GOAL;
    this.goal = [row, col];
  }

  @action movePlayer(direction) {
    const [row, col] = this.player;
    this.cells[row][col].data = null;

    const [nextRow, nextCol] = next(row, col, direction);
    this.cells[nextRow][nextCol].data = PLAYER;

    this.player = [nextRow, nextCol];
  }
}

function isValidCell(row, col) {
  return row >= 0 && row < 6 && col >= 0 && col < 6;
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

function directionBetweenCells([row1, col1], [row2, col2]) {
  for (let direction = TOP; direction <= LEFT; direction++) {
    const [nextRow, nextCol] = next(row1, col1, direction);
    if (nextRow === row2 && nextCol === col2) {
      return direction;
    }
  }

  return null;
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
