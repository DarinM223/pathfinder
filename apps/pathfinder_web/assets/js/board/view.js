import React, { Component, PropTypes } from 'react';
import {observer} from 'mobx-react';
import {
  TOP,
  RIGHT,
  BOTTOM,
  LEFT,
  PLAYER,
  GOAL,
  SELECTED_HIGHLIGHT,
  HINT_HIGHLIGHT,
  PLACE_WALL,
  PLACE_PLAYER,
  PLACE_GOAL,
  MOVE_PLAYER,
  directionBetweenCells
} from './data.js';

const styles = {
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

function addWalls(style, walls, backgroundColor) {
  return {
    ...style,
    backgroundColor: backgroundColor,
    borderTopColor: walls[TOP] ? 'black' : 'white',
    borderRightColor: walls[RIGHT] ? 'black' : 'white',
    borderBottomColor: walls[BOTTOM] ? 'black' : 'white',
    borderLeftColor: walls[LEFT] ? 'black' : 'white'
  };
}

@observer
export class CellView extends Component {
  render() {
    let cellText = null;
    switch (this.props.cell.data) {
      case PLAYER:
        cellText = 'P';
        break;
      case GOAL:
        cellText = 'G';
        break;
    }

    let backgroundColor = null;
    switch (this.props.cell.highlight) {
      case SELECTED_HIGHLIGHT:
        backgroundColor = '#FFA500';
        break;
      case HINT_HIGHLIGHT:
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

@observer
export class BoardView extends Component {
  onCellClick(row, col) {
    switch (this.props.board.state.type) {
      case PLACE_WALL:
        this.props.board.placeWall(row, col);
        break;
      case PLACE_GOAL:
        this.props.board.placeGoal(row, col);
        break;
      case MOVE_PLAYER:
        const direction = directionBetweenCells(this.props.board.player, [row, col]);
        if (direction !== null) {
          this.props.movePlayer(direction);
        }
        break;
      case PLACE_PLAYER:
        if (col === 0) {
          this.props.placePlayer(row);
        }
        break;
    }
  }

  render() {
    const cells = this.props.board.cells;

    const rows = [];
    for (let row = 0; row < 6; row++) {
      const cellViews = [];
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
