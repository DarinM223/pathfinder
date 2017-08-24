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
export const SUCCESS_HIGHLIGHT = 'SUCCESS_HIGHLIGHT';
export const SELECTED_HIGHLIGHT = 'INFO_HIGHLIGHT';
export const HINT_HIGHLIGHT = 'HINT_HIGHLIGHT';

export const PLAYER = 'PLAYER';
export const GOAL = 'GOAL';
export const MARKER = 'MARKER';

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
export const WON_STATE = 'WON_STATE';

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
   *
   * Won:
   * { type: 'WON_STATE' }
   */
  @observable state = { type: NO_STATE };

  @computed get setWallActions() {
    const walls = [];
    for (let row = 0; row < 6; row++) {
      // Set walls in middle.
      for (let col = 0; col < 6; col++) {
        for (const direction of [RIGHT, BOTTOM]) {
          const [nextRow, nextCol] = next(row, col, direction);
          if (isValidCell(nextRow, nextCol) && this.cells[row][col].walls[direction] === true) {
            walls.push({
              name: 'set_wall',
              params: [[row + 1, col + 1], [nextRow + 1, nextCol + 1], true],
            });
          }
        }
      }

      // Set row walls.
      if (this.cells[row][0].walls[LEFT] === true) {
        walls.push({
          name: 'set_wall',
          params: [row + 1, true],
        });
      }
    }

    return walls;
  }

  @action loadFromJSON(board) {
    this.player = board.player;
    this.goal = board.goal;
    this.cells = board.cells;
    this.state = board.state;
  }

  @action loadFromBackend(board) {
    this.player = board.player;
    this.goal = board.goal;

    for (const boardCell of board.cells) {
      const cell = new Cell();
      if (boardCell.data === 'marker') {
        cell.data = MARKER;
      }
      cell.walls = [
        boardCell.top,
        boardCell.right,
        boardCell.bottom,
        boardCell.left
      ];
      this.cells[boardCell.row][boardCell.col] = cell;
    }

    if (this.player !== null) {
      this.cells[this.player[0]][this.player[1]].data = PLAYER;
    }
    if (this.goal !== null) {
      this.cells[this.goal[0]][this.goal[1]].data = GOAL;
    }
  }

  @action applyAction(action) {
    switch (action.name) {
      case 'set_wall':
        if (action.params.length === 3) {
          const [pos1, pos2] = [convertPosition(action.params[0]), convertPosition(action.params[1])];
          const direction = directionBetweenCells(pos1, pos2);
          this.setWall(...pos1, direction, action.params[2]);
        } else {
          this.toggleRowWall(action.params[0] - 1);
        }
        break;
      case 'place_goal':
        this.placeGoal(...convertPosition(action.params[0]));
        break;
      case 'place_player':
        const row = action.params[0] - 1;
        this.temporaryHighlight(row, 0, HINT_HIGHLIGHT);
        this.placePlayer(row);
        break;
      case 'move_player':
        const direction = action.params[0] - 1;
        const nextPosition = next(...this.player, direction);
        this.temporaryHighlight(...nextPosition, HINT_HIGHLIGHT);
        this.movePlayer(direction);
        break;
      case 'remove_player':
        this.temporaryHighlight(...this.player, HINT_HIGHLIGHT);
        action.params.push(this.player[0]);
        this.removePlayer();
        break;
      case 'highlight_position':
        const position = convertPosition(action.params[0]);
        this.temporaryHighlight(...position, HINT_HIGHLIGHT);
        break;
    }
  }

  @action undoAction(action) {
    const oldPosition = this.player;
    switch (action.name) {
      case 'place_player':
        if (this.player !== null) {
          this.removePlayer(false);
          if (this.goal !== null &&
              this.goal[0] === oldPosition[0] &&
              this.goal[1] === oldPosition[1]) {
            this.placeGoal(...this.goal);
          }
        }
        break;
      case 'move_player':
        this.movePlayer(reverse(action.params[0] - 1), false);
        if (this.goal !== null &&
            this.goal[0] === oldPosition[0] &&
            this.goal[1] === oldPosition[1]) {
          this.placeGoal(...this.goal);
        }
        break;
      case 'remove_player':
        const row = action.params.pop();
        this.placePlayer(row);
        break;
    }
  }

  @action transition(state) {
    // Clear highlights from the grid.
    this.clearGrid();

    let row = null, col = null;
    switch (state) {
      case PLACE_WALL:
        this.state = { type: state, firstCell: null };
        return;
      case MOVE_PLAYER:
        ;[row, col] = this.player;
        this.toggleHighlight(row, col, false);
        break;
      case PLACE_PLAYER:
        for (let row = 0; row < 6; row++) {
          this.cells[row][0].highlight = HINT_HIGHLIGHT;
        }
        break;
      case WON_STATE:
        ;[row, col] = this.player;
        this.cells[row][col].highlight = SUCCESS_HIGHLIGHT;
        break;
    }
    this.state = { type: state };
  }

  @action placeWall(row, col) {
    if (this.state.firstCell === null) {
      this.toggleHighlight(row, col);
      this.state.firstCell = [row, col];
      return;
    }

    // If the cell is clicked twice if the cell
    // is on the first column, set the row wall.
    if (this.state.firstCell[0] === row &&
        this.state.firstCell[1] === col &&
        col === 0) {
      this.toggleRowWall(row);
      this.resetPlaceWall();
      return;
    }

    // Otherwise set the wall between the two cells or
    // reset if the cells aren't adjacent to each other.
    const direction = directionBetweenCells(this.state.firstCell, [row, col]);
    if (direction === null) {
      this.resetPlaceWall();
      return;
    }

    this.toggleWall(this.state.firstCell[0], this.state.firstCell[1], direction);
    this.resetPlaceWall();
  }

  @action placeGoal(row, col) {
    if (this.goal !== null) {
      const [goalRow, goalCol] = this.goal;
      this.cells[goalRow][goalCol].data = null;
    }

    this.cells[row][col].data = GOAL;
    this.goal = [row, col];
  }

  @action resetPlaceWall() {
    const [row, col] = this.state.firstCell;
    this.toggleHighlight(row, col);
    this.state.firstCell = null;
  }

  @action clearGrid() {
    for (let row = 0; row < 6; row++) {
      for (let col = 0; col < 6; col++) {
        if (this.cells[row][col].highlight) {
          this.cells[row][col].highlight = null;
        }
      }
    }
  }

  @action toggleHighlight(row, col, goThroughWalls = true) {
    this.cells[row][col].highlight =
      this.cells[row][col].highlight ? null : SELECTED_HIGHLIGHT;

    for (let direction = TOP; direction <= LEFT; direction++) {
      if (goThroughWalls === false &&
          this.cells[row][col].walls[direction] === true) {
        continue;
      }

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

  @action setWall(row, col, direction, wall = true) {
    this.cells[row][col].walls[direction] = wall;

    const [nextRow, nextCol] = next(row, col, direction);
    const reversedDirection = reverse(direction);
    this.cells[nextRow][nextCol].walls[reversedDirection] = wall;
  }

  @action toggleRowWall(row) {
    this.cells[row][0].walls[LEFT] =
      !this.cells[row][0].walls[LEFT];
  }

  @action placePlayer(row) {
    if (this.cells[row][0].walls[LEFT] === true) {
      return;
    }

    if (this.player !== null) {
      const [playerRow, playerCol] = this.player;
      this.cells[playerRow][playerCol].data = null;
    }
    this.cells[row][0].data = PLAYER;
    this.player = [row, 0];
  }

  @action movePlayer(direction, addMarker = true) {
    const [row, col] = this.player;
    if (this.cells[row][col].walls[direction] === true) {
      return;
    }

    const [nextRow, nextCol] = next(row, col, direction);
    if (!isValidCell(nextRow, nextCol)) {
      return;
    }

    if (addMarker) {
      this.cells[row][col].data = MARKER;
    } else {
      this.cells[row][col].data = null;
    }
    this.cells[nextRow][nextCol].data = PLAYER;
    this.player = [nextRow, nextCol];
  }

  @action removePlayer(addMarker = true) {
    const [row, col] = this.player;
    if (this.cells[row][col].walls[LEFT] === true) {
      return;
    }

    if (addMarker) {
      this.cells[row][col].data = MARKER;
    } else {
      this.cells[row][col].data = null;
    }

    this.player = null;
  }

  @action removeGoal() {
    const [row, col] = this.goal;
    this.cells[row][col].data = null;

    this.goal = null;
  }

  @action temporaryHighlight(row, col, highlight, timeout = 1000) {
    this.cells[row][col].highlight = highlight;
    setTimeout(() => {
      this.cells[row][col].highlight = null;
    }, timeout);
  }
}

export function isValidCell(row, col) {
  return row >= 0 && row < 6 && col >= 0 && col < 6;
}

export function next(row, col, direction) {
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

export function directionBetweenCells([row1, col1], [row2, col2]) {
  for (let direction = TOP; direction <= LEFT; direction++) {
    const [nextRow, nextCol] = next(row1, col1, direction);
    if (nextRow === row2 && nextCol === col2) {
      return direction;
    }
  }

  return null;
}

export function reverse(direction) {
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

export function convertPosition([row, col]) {
  return [row - 1, col - 1];
}

export function storageId(gameId) {
  return `${gameId}_board`;
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
