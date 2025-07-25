import React from 'react';
import CopyToClipboard from 'react-copy-to-clipboard-ts';
import { Board } from './board/data.ts';
import { Game } from './game.tsx';

const styles: { alignedToBoard: React.CSSProperties, middleButton: React.CSSProperties } = {
  alignedToBoard: {
    marginLeft: '10px',
    marginRight: '5px'
  },
  middleButton: {
    marginLeft: '0px',
    marginRight: '5px'
  }
};

const buildButtonOpts = {
  "data-toggle": "modal",
  "data-target": "#validateModal"
};

const clearButtonOpts = {
  "data-toggle": "modal",
  "data-target": "#clearModal"
};

const dismissButtonOpts = {
  "data-dismiss": "modal"
};

export const switchButton = (board: Board) => {
  switch (board.state.type) {
    case 'PLACE_GOAL':
      return (
        <button
          style={styles.alignedToBoard}
          className="btn btn-info"
          onClick={e => board.transition('PLACE_WALL')}>
          Place walls
        </button>
      );
    case 'PLACE_WALL':
      return (
        <button
          style={styles.alignedToBoard}
          className="btn btn-info"
          onClick={e => board.transition('PLACE_GOAL')}>
          Place goal
        </button>
      );
    default:
      return null;
  }
};

export const boardStatus = (board: Board) => {
  switch (board.state.type) {
    case 'PLACE_GOAL':
      return "(placing goal)";
    case 'PLACE_WALL':
      return "(placing walls)";
    default:
      return null;
  }
};

export const shareButton = (game: Game) => {
  if (game.shareId !== null && game.shareId.trim().length > 0) {
    return (
      <CopyToClipboard text={game.shareId}>
        <button style={styles.alignedToBoard} className="btn btn-info">Copy share url</button>
      </CopyToClipboard>
    );
  }
  return null;
};

export const buildButton = (board: Board) => {
  if (board.state.type === 'PLACE_GOAL' ||
    board.state.type === 'PLACE_WALL') {
    return (
      <button className="btn btn-success" {...buildButtonOpts}>
        Validate
      </button>
    );
  }
  return null;
};

export const clearButton = (board: Board) => {
  if (board.state.type === 'PLACE_GOAL' ||
    board.state.type === 'PLACE_WALL') {
    return (
      <button style={styles.middleButton} className="btn btn-danger" {...clearButtonOpts}>
        Clear board
      </button>
    );
  }
};

export const clearModal = (clearFn: React.MouseEventHandler<HTMLButtonElement>) => (
  <div id="clearModal" className="modal fade" role="dialog">
    <div className="modal-dialog">
      <div className="modal-content">
        <div className="modal-body">
          <p>Are you are sure you want to remove all changes you made to the maze?</p>
        </div>
        <div className="modal-footer">
          <button
            type="button"
            className="btn btn-success"
            onClick={clearFn}
            {...dismissButtonOpts}>
            Yes
          </button>
          <button
            type="button"
            className="btn btn-info"
            {...dismissButtonOpts}>
            No
          </button>
        </div>
      </div>
    </div>
  </div>
);

export const buildModal = (buildFn: React.MouseEventHandler<HTMLButtonElement>) => (
  <div id="validateModal" className="modal fade" role="dialog">
    <div className="modal-dialog">
      <div className="modal-content">
        <div className="modal-body">
          <p>Are you are sure you are finished building the maze?</p>
        </div>
        <div className="modal-footer">
          <button
            type="button"
            className="btn btn-success"
            onClick={buildFn}
            {...dismissButtonOpts}>
            Yes
          </button>
          <button
            type="button"
            className="btn btn-info"
            {...dismissButtonOpts}>
            No
          </button>
        </div>
      </div>
    </div>
  </div>
);
