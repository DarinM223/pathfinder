import React, { Component } from 'react';
import { observer } from 'mobx-react';
import {
  Direction,
  Cell,
  CellData,
  Highlight,
  BoardState,
  Board,
  directionBetweenCells,
  storageId
} from './data.ts';

const styles: { square: React.CSSProperties } = {
  square: {
    width: '50px',
    height: '50px',
    float: 'left',
    borderWidth: '5px',
    borderStyle: 'solid',
    textAlign: 'center',
    verticalAlign: 'middle',
    lineHeight: '40px'
  }
};

function addWalls(style: React.CSSProperties, walls: boolean[], backgroundColor: string): React.CSSProperties {
  return {
    ...style,
    backgroundColor: backgroundColor,
    borderTopColor: walls[Direction.Top] ? 'black' : 'white',
    borderRightColor: walls[Direction.Right] ? 'black' : 'white',
    borderBottomColor: walls[Direction.Bottom] ? 'black' : 'white',
    borderLeftColor: walls[Direction.Left] ? 'black' : 'white'
  };
}

type CellViewProps = {
  cell: Cell,
  onClick: (e: React.MouseEvent<HTMLDivElement, MouseEvent>) => void,
}

@observer
export class CellView extends Component<CellViewProps, {}> {
  render() {
    let cellText: string | null = null;
    switch (this.props.cell.data) {
      case CellData.Player:
        cellText = 'P';
        break;
      case CellData.Goal:
        cellText = 'G';
        break;
      case CellData.Marker:
        cellText = '0';
        break;
    }

    let backgroundColor: string | null = null;
    switch (this.props.cell.highlight) {
      case Highlight.Success:
        backgroundColor = '#87CEFA';
        break;
      case Highlight.Selected:
        backgroundColor = '#FFA500';
        break;
      case Highlight.Hint:
        backgroundColor = '#7CFC00';
        break;
      default:
        backgroundColor = '#D3D3D3';
        break;
    }

    return (
      <div
        className="col"
        style={addWalls(styles.square, this.props.cell.walls, backgroundColor)}
        onClick={e => this.props.onClick(e)}>
        <b>{cellText}</b>
      </div>
    );
  }
}

type BoardViewProps = {
  gameId: string | null,
  board: Board,
  removePlayer: (row: number) => void,
  movePlayer: (direction: Direction) => void,
  placePlayer: (row: number) => void,
}

@observer
export class BoardView extends Component<BoardViewProps, {}> {
  static defaultProps = {
    removePlayer: (_: number) => { },
    movePlayer: (_: Direction) => { },
    placePlayer: (_: number) => { },
  }

  onCellClick(row: number, col: number) {
    const player = this.props.board.player;
    switch (this.props.board.state.type) {
      case 'PLACE_WALL':
        this.props.board.placeWall(row, col);
        if (this.props.gameId !== null) {
          localStorage.setItem(storageId(this.props.gameId), JSON.stringify(this.props.board));
        }
        break;
      case 'PLACE_GOAL':
        this.props.board.placeGoal(row, col);
        if (this.props.gameId !== null) {
          localStorage.setItem(storageId(this.props.gameId), JSON.stringify(this.props.board));
        }
        break;
      case 'MOVE_PLAYER':
        if (player !== null) {
          if (player[0] === row && player[1] === col && col === 0) {
            this.props.removePlayer(row);
          } else {
            const direction = directionBetweenCells(player, [row, col]);
            if (direction !== null &&
              this.props.board.cells[player[0]][player[1]].walls[direction] === false) {
              this.props.movePlayer(direction);
            }
          }
        }
        break;
      case 'PLACE_PLAYER':
        if (col === 0) {
          this.props.placePlayer(row);
        }
        break;
    }
  }

  render() {
    const cells = this.props.board.cells;

    const rows: React.ReactElement[] = [];
    for (let row = 0; row < 6; row++) {
      const cellViews: React.ReactElement[] = [];
      for (let col = 0; col < 6; col++) {
        cellViews.push(<CellView
          cell={cells[row][col]}
          onClick={e => this.onCellClick(row, col)}
        />);
      }

      rows.push(<div className="container">{cellViews}</div>);
    }

    return <div>{rows}</div>;
  }
}
