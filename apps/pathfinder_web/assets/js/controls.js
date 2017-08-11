import React from 'react';
import CopyToClipboard from 'react-copy-to-clipboard';
import {
  PLACE_WALL,
  PLACE_GOAL
} from './board/data.js';

const buttonStyle = {
  marginLeft: '10px',
  marginRight: '5px'
};

const buildButtonOpts = {
  "data-toggle": "modal",
  "data-target": "#validateModal"
};

const dismissButtonOpts = {
  "data-dismiss": "modal"
};

export const switchButton = (board) => {
  switch (board.state.type) {
    case PLACE_GOAL:
      return (
        <button
          style={buttonStyle}
          className="btn btn-info"
          onClick={e => board.transition(PLACE_WALL)}>
          Place walls
        </button>
      );
    case PLACE_WALL:
      return (
        <button
          style={buttonStyle}
          className="btn btn-info"
          onClick={e => board.transition(PLACE_GOAL)}>
          Place goal
        </button>
      );
    default:
      return null;
  }
};

export const boardStatus = (board) => {
  switch (board.state.type) {
    case PLACE_GOAL:
      return "(placing goal)";
    case PLACE_WALL:
      return "(placing walls)";
    default:
      return null;
  }
};

export const shareButton = (game) => {
  if (game.shareId !== null && game.shareId.trim().length > 0) {
    return (
      <CopyToClipboard text={game.shareId}>
        <button style={buttonStyle} className="btn btn-info">Copy share url</button>
      </CopyToClipboard>
    );
  }
  return null;
};

export const buildButton = (board) => {
  if (board.state.type === PLACE_GOAL ||
      board.state.type === PLACE_WALL) {
    return (
      <button className="btn btn-success" {...buildButtonOpts}>
        Validate
      </button>
    );
  }
  return null;
};

export const buildModal = (buildFn) => (
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
