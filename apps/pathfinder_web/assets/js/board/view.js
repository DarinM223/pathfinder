import React, { Component, PropTypes } from 'react';
import {observer} from 'mobx-react';
import {TOP, RIGHT, BOTTOM, LEFT} from './data.js';

const styles = {
  square: {
    width: '50px',
    height: '50px',
    float: 'left',
    backgroundColor: '#D3D3D3',
    borderWidth: '5px',
    borderStyle: 'solid',
    borderRadius: '25px',
  }
};

function addWalls(style, walls) {
  return {
    ...style,
    borderTopColor: walls[TOP] ? 'black' : 'white',
    borderRightColor: walls[RIGHT] ? 'black' : 'white',
    borderBottomColor: walls[BOTTOM] ? 'black' : 'white',
    borderLeftColor: walls[LEFT] ? 'black' : 'white'
  };
}

@observer
export class CellView extends Component {
  render() {
    return (
      <div
        className="col"
        style={addWalls(styles.square, this.props.cell.walls)}
      />
    );
  }
}

@observer
export class BoardView extends Component {
  render() {
    const cells = this.props.board.cells;

    const rows = [];
    for (let row = 0; row < 6; row++) {
      const cellViews = [];
      for (let col = 0; col < 6; col++) {
        cellViews.push(<CellView cell={cells[row][col]} />);
      }

      rows.push(<div className="container">{cellViews}</div>);
    }

    return <div>{rows}</div>;
  }
}
