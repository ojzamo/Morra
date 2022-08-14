import React, { useState } from "react";

const exports = {};

// Player views must be extended.
// It does not have its own Wrapper view.

exports.GetFingers = class extends React.Component {
  render() {
    const { parent, playable, guessed, listFingers, listGuess, isDraw } =
      this.props;
    const Fingers = ({ outcome }) => {
      return (
        <div>
          <button
            onClick={() =>
              !guessed ? parent.playFingers(outcome) : parent.playGuess(outcome)
            }
          >
            {outcome}
          </button>
        </div>
      );
    };

    return (
      <div>
        {isDraw ? "It was a draw! Pick again." : ""}
        <br />
        {!playable
          ? "Please wait..."
          : !guessed
          ? "Pick your choice of fingers"
          : "Guess the total fingers played"}
        <div>
          {playable &&
            !guessed &&
            listFingers.map((el, i) => <Fingers outcome={el} key={i} />)}
          {playable &&
            guessed &&
            listGuess.map((el, i) => <Fingers outcome={el} key={i} />)}
        </div>
      </div>
    );
  }
};

exports.WaitingForResults = class extends React.Component {
  render() {
    return <div>Waiting for results...</div>;
  }
};

exports.Wining = class extends React.Component {
  render() {
    const { winningNumber } = this.props;
    return (
      <div>
        The winner number was:
        <br />
        {winningNumber || "Unknown"}
      </div>
    );
  }
};

exports.Done = class extends React.Component {
  render() {
    const { outcome } = this.props;
    return (
      <div>
        Thank you for playing. The outcome of this game was:
        <br />
        {outcome || "Unknown"}
      </div>
    );
  }
};

exports.Timeout = class extends React.Component {
  render() {
    return <div>There's been a timeout. (Someone took too long.)</div>;
  }
};

export default exports;
