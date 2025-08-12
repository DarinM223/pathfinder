import { action, observable, computed, runInAction } from 'mobx';

/*
 * Direction types.
 */
export enum Direction {
  Top = 0,
  Right = 1,
  Bottom = 2,
  Left = 3,
}

/*
 * Cell highlight types.
 */
export enum Highlight {
  Success = 'SUCCESS_HIGHLIGHT',
  Selected = 'INFO_HIGHLIGHT',
  Hint = 'HINT_HIGHLIGHT',
}

export enum CellData {
  Player = 'PLAYER',
  Goal = 'GOAL',
  Marker = 'MARKER',
}

export class Cell {
  @observable accessor data: CellData | null = null;
  @observable accessor walls = [false, false, false, false];
  @observable accessor highlight: Highlight | null = null;

  /**
   * Observable accessors are now properties and are not enumerable.
   * So JSON stringify won't work without explicitly specifying this.
   * @returns a JSON objects with the properties
   */
  toJSON() {
    return {
      data: this.data,
      walls: this.walls,
      highlight: this.highlight,
    };
  }

  @action loadFromJSON(cell: Cell) {
    this.data = cell.data;
    this.walls = cell.walls;
    this.highlight = cell.highlight;
  }

  constructor() { }
}

/*
 * Valid board state types.
 */
export type BoardState =
  { type: 'NO_STATE' } |
  {
    type: 'PLACE_WALL',
    firstCell: [number, number] | null
  } |
  { type: 'PLACE_GOAL' } |
  { type: 'MOVE_PLAYER' } |
  { type: 'PLACE_PLAYER' } |
  { type: 'WON_STATE' }

export type Action =
  { user_id?: string, succeeded: boolean } &
  ({ name: 'set_wall', params: [number, boolean] | [[number, number], [number, number], boolean] }
    | { name: 'place_goal', params: [[number, number]] } // Position where goal is placed.
    | { name: 'place_player', params: [number] } // Row where player is placed.
    | { name: 'move_player', params: [Direction] }
    | { name: 'remove_player', params: number[] } // Stores row where player is removed.
    | { name: 'highlight_position', params: [[number, number]] } // Position to highlight.
  )

export type BackendBoardCell = {
  data: string,
  top: boolean,
  right: boolean,
  bottom: boolean,
  left: boolean,
  row: number,
  col: number
}

export type BackendBoard = {
  player: Board["player"],
  goal: Board["goal"],
  cells: BackendBoardCell[],
}

export class Board {
  @observable accessor cells = makeCells();
  @observable accessor player: [number, number] | null = null;
  @observable accessor goal: [number, number] | null = null;
  @observable accessor state: BoardState = { type: 'NO_STATE' };

  /**
   * Observable accessors are now properties and are not enumerable.
   * So JSON stringify won't work without explicitly specifying this.
   * @returns a JSON objects with the properties
   */
  toJSON() {
    return {
      cells: this.cells.map((cells) => cells.map((cell) => cell.toJSON())),
      player: this.player,
      goal: this.goal,
      state: this.state,
    };
  }

  @computed get setWallActions() {
    const walls: Action[] = [];
    for (let row = 0; row < 6; row++) {
      // Set walls in middle.
      for (let col = 0; col < 6; col++) {
        for (const direction of [Direction.Right, Direction.Bottom]) {
          const [nextRow, nextCol] = next(row, col, direction);
          if (isValidCell(nextRow, nextCol) && this.cells[row][col].walls[direction] === true) {
            walls.push({
              name: 'set_wall',
              params: [[row + 1, col + 1], [nextRow + 1, nextCol + 1], true],
              succeeded: false,
            });
          }
        }
      }

      // Set row walls.
      if (this.cells[row][0].walls[Direction.Left] === true) {
        walls.push({
          name: 'set_wall',
          params: [row + 1, true],
          succeeded: false,
        });
      }
    }

    return walls;
  }

  @action loadFromJSON(board: Board) {
    this.player = board.player;
    this.goal = board.goal;
    this.cells = board.cells.map((cells) => cells.map((cell) => {
      const newCell = new Cell();
      newCell.loadFromJSON(cell);
      return newCell;
    }));
    this.state = board.state;
  }

  @action loadFromBackend(board: BackendBoard) {
    this.player = board.player;
    this.goal = board.goal;

    for (const boardCell of board.cells) {
      const cell = new Cell();
      if (boardCell.data === 'marker') {
        cell.data = CellData.Marker;
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
      this.cells[this.player[0]][this.player[1]].data = CellData.Player;
    }
    if (this.goal !== null) {
      this.cells[this.goal[0]][this.goal[1]].data = CellData.Goal;
    }
  }

  @action applyAction(action: Action) {
    switch (action.name) {
      case 'set_wall':
        if (action.params.length === 3) {
          const [pos1, pos2] = [convertPosition(action.params[0]), convertPosition(action.params[1])];
          const direction = directionBetweenCells(pos1, pos2);
          if (direction !== null) {
            this.setWall(...pos1, direction, action.params[2]);
          }
        } else {
          this.toggleRowWall(action.params[0] - 1);
        }
        break;
      case 'place_goal':
        this.placeGoal(...convertPosition(action.params[0]));
        break;
      case 'place_player':
        const row = action.params[0] - 1;
        this.temporaryHighlight(row, 0, Highlight.Hint);
        action.succeeded = this.placePlayer(row);
        break;
      case 'move_player':
        const direction = action.params[0] - 1;
        const nextPosition = next(...this.player!, direction);
        this.temporaryHighlight(...nextPosition, Highlight.Hint);
        action.succeeded = this.movePlayer(direction);
        break;
      case 'remove_player':
        this.temporaryHighlight(...this.player!, Highlight.Hint);
        action.params.push(this.player![0]);
        this.removePlayer();
        break;
      case 'highlight_position':
        const position = convertPosition(action.params[0]);
        this.temporaryHighlight(...position, Highlight.Hint);
        break;
    }
  }

  @action undoAction(action: Action) {
    switch (action.name) {
      case 'place_player':
        this.temporaryHighlight(action.params[0] - 1, 0, Highlight.Hint);
        if (this.player !== null) {
          const oldPosition = this.player;
          this.removePlayer(false);
          if (this.goal !== null &&
            this.goal[0] === oldPosition[0] &&
            this.goal[1] === oldPosition[1]) {
            this.placeGoal(...this.goal);
          }
        }
        break;
      case 'move_player':
        if (this.player !== null) {
          const oldPosition = this.player;
          if (action.succeeded) {
            this.movePlayer(reverse(action.params[0] - 1), false);
          } else {
            const position = next(...this.player!, action.params[0] - 1);
            this.temporaryHighlight(...position, Highlight.Hint);
          }
          if (this.goal !== null &&
            this.goal[0] === oldPosition[0] &&
            this.goal[1] === oldPosition[1]) {
            this.placeGoal(...this.goal);
          }
        }
        break;
      case 'remove_player':
        const row = action.params.pop();
        if (typeof row !== 'undefined') {
          this.placePlayer(row);
        }
        break;
    }
  }

  @action transition(type: BoardState["type"]) {
    // Clear highlights from the grid.
    this.clearGrid();

    switch (type) {
      case 'PLACE_WALL':
        this.state = { type, firstCell: null };
        return;
      case 'MOVE_PLAYER':
        {
          let [row, col] = this.player!;
          this.toggleHighlight(row, col, false);
          break;
        }
      case 'PLACE_PLAYER':
        for (let row = 0; row < 6; row++) {
          this.cells[row][0].highlight = Highlight.Hint;
        }
        break;
      case 'WON_STATE':
        {
          let [row, col] = this.player!;
          this.cells[row][col].highlight = Highlight.Success;
          break;
        }
    }
    this.state.type = type;
  }

  @action placeWall(row: number, col: number) {
    if (this.state.type != 'PLACE_WALL') {
      return;
    }
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

  @action placeGoal(row: number, col: number) {
    if (this.goal !== null) {
      const [goalRow, goalCol] = this.goal;
      this.cells[goalRow][goalCol].data = null;
    }

    this.cells[row][col].data = CellData.Goal;
    this.goal = [row, col];
  }

  @action resetPlaceWall() {
    if (this.state.type != 'PLACE_WALL') {
      return;
    }
    const [row, col] = this.state.firstCell!;
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

  @action toggleHighlight(row: number, col: number, goThroughWalls = true) {
    this.cells[row][col].highlight =
      this.cells[row][col].highlight ? null : Highlight.Selected;

    for (let direction = Direction.Top; direction <= Direction.Left; direction++) {
      if (goThroughWalls === false &&
        this.cells[row][col].walls[direction] === true) {
        continue;
      }

      const [nextRow, nextCol] = next(row, col, direction);
      if (isValidCell(nextRow, nextCol)) {
        this.cells[nextRow][nextCol].highlight =
          this.cells[nextRow][nextCol].highlight ? null : Highlight.Hint;
      }
    }
  }

  @action toggleWall(row: number, col: number, direction: Direction) {
    this.cells[row][col].walls[direction] =
      !this.cells[row][col].walls[direction];

    const [nextRow, nextCol] = next(row, col, direction);
    const reversedDirection = reverse(direction);
    this.cells[nextRow][nextCol].walls[reversedDirection] =
      !this.cells[nextRow][nextCol].walls[reversedDirection];
  }

  @action setWall(row: number, col: number, direction: Direction, wall = true) {
    this.cells[row][col].walls[direction] = wall;

    const [nextRow, nextCol] = next(row, col, direction);
    const reversedDirection = reverse(direction);
    this.cells[nextRow][nextCol].walls[reversedDirection] = wall;
  }

  @action toggleRowWall(row: number) {
    this.cells[row][0].walls[Direction.Left] =
      !this.cells[row][0].walls[Direction.Left];
  }

  @action placePlayer(row: number): boolean {
    if (this.cells[row][0].walls[Direction.Left] === true) {
      return false;
    }

    if (this.player !== null) {
      const [playerRow, playerCol] = this.player;
      this.cells[playerRow][playerCol].data = null;
    }
    this.cells[row][0].data = CellData.Player;
    this.player = [row, 0];
    return true;
  }

  @action movePlayer(direction: Direction, addMarker = true): boolean {
    const [row, col] = this.player!;
    if (this.cells[row][col].walls[direction] === true) {
      return false;
    }

    const [nextRow, nextCol] = next(row, col, direction);
    if (!isValidCell(nextRow, nextCol)) {
      return false;
    }

    if (addMarker) {
      this.cells[row][col].data = CellData.Marker;
    } else {
      this.cells[row][col].data = null;
    }
    this.cells[nextRow][nextCol].data = CellData.Player;
    this.player = [nextRow, nextCol];
    return true;
  }

  @action removePlayer(addMarker = true) {
    const [row, col] = this.player!;
    if (this.cells[row][col].walls[Direction.Left] === true) {
      return;
    }

    if (addMarker) {
      this.cells[row][col].data = CellData.Marker;
    } else {
      this.cells[row][col].data = null;
    }

    this.player = null;
  }

  @action removeGoal() {
    const [row, col] = this.goal!;
    this.cells[row][col].data = null;

    this.goal = null;
  }

  @action temporaryHighlight(row: number, col: number, highlight: Highlight, timeout = 1000) {
    this.cells[row][col].highlight = highlight;
    setTimeout(() => {
      runInAction(() => { this.cells[row][col].highlight = null; });
    }, timeout);
  }
}

export function isValidCell(row: number, col: number) {
  return row >= 0 && row < 6 && col >= 0 && col < 6;
}

export function next(row: number, col: number, direction: Direction): [number, number] {
  switch (direction) {
    case Direction.Top:
      return [row - 1, col];
    case Direction.Right:
      return [row, col + 1];
    case Direction.Bottom:
      return [row + 1, col];
    case Direction.Left:
      return [row, col - 1];
  }
}

export function directionBetweenCells([row1, col1]: [number, number], [row2, col2]: [number, number]): Direction | null {
  for (let direction = Direction.Top; direction <= Direction.Left; direction++) {
    const [nextRow, nextCol] = next(row1, col1, direction);
    if (nextRow === row2 && nextCol === col2) {
      return direction;
    }
  }

  return null;
}

export function reverse(direction: Direction): Direction {
  switch (direction) {
    case Direction.Top:
      return Direction.Bottom;
    case Direction.Right:
      return Direction.Left;
    case Direction.Bottom:
      return Direction.Top;
    case Direction.Left:
      return Direction.Right;
  }
}

export function convertPosition([row, col]: [number, number]): [number, number] {
  return [row - 1, col - 1];
}

export function storageId(gameId: string): string {
  return `${gameId}_board`;
}

function makeCells(): Cell[][] {
  let cells: Cell[][] = [];
  for (let i = 0; i < 6; i++) {
    let row: Cell[] = [];
    for (let j = 0; j < 6; j++) {
      row.push(new Cell());
    }

    cells.push(row);
  }

  for (let col = 0; col < 6; col++) {
    cells[0][col].walls[Direction.Top] = true;
    cells[cells.length - 1][col].walls[Direction.Bottom] = true;
  }
  for (let row = 0; row < 6; row++) {
    cells[row][cells[row].length - 1].walls[Direction.Right] = true;
  }
  return cells;
}
