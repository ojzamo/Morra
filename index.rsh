"reach 0.1";

const [isFingers, ZERO, ONE, TWO, THREE, FOUR, FIVE] = makeEnum(6);
const [
  isGuess,
  ZEROG,
  ONEG,
  TWOG,
  THREEG,
  FOURG,
  FIVEG,
  SIXG,
  SEVENG,
  EIGHTG,
  NINEG,
  TENG,
] = makeEnum(11);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

const winner = (fingersAlice, fingersBob, guessAlice, guessBob) => {
  if (guessAlice == guessBob) {
    const myoutcome = DRAW;
    return myoutcome;
  } else {
    if (fingersAlice + fingersBob == guessAlice) {
      const myoutcome = A_WINS;
      return myoutcome;
    } else {
      if (fingersAlice + fingersBob == guessBob) {
        const myoutcome = B_WINS;
        return myoutcome;
      } else {
        const myoutcome = DRAW;
        return myoutcome;
      }
    }
  }
};

assert(winner(ZERO, TWO, ZEROG, TWOG) == B_WINS);
assert(winner(TWO, ZERO, TWOG, ZEROG) == A_WINS);
assert(winner(ZERO, ONE, ZEROG, TWOG) == DRAW);
assert(winner(ONE, ONE, ONEG, ONEG) == DRAW);

forall(UInt, (fingersA) =>
  forall(UInt, (fingersB) =>
    forall(UInt, (guessA) =>
      forall(UInt, (guessB) =>
        assert(isOutcome(winner(fingersA, fingersB, guessA, guessB)))
      )
    )
  )
);

forall(UInt, (fingerA) =>
  forall(UInt, (fingerB) =>
    forall(UInt, (guess) =>
      assert(winner(fingerA, fingerB, guess, guess) == DRAW)
    )
  )
);

const Player = {
  ...hasRandom,
  getFingers: Fun([], UInt),
  getGuess: Fun([UInt], UInt),
  seeWinning: Fun([UInt], Null),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

const DEADLINE = 30;

export const main = Reach.App(() => {
  const Alice = Participant("Alice", {
    ...Player,
    wager: UInt,
    deadline: UInt,
  });
  const Bob = Participant("Bob", {
    ...Player,
    acceptWager: Fun([UInt], Null),
  });
  init();
  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, deadline).pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager);
  });
  Bob.pay(wager).timeout(relativeTime(deadline), () =>
    closeTo(Alice, informTimeout)
  );

  var outcome = DRAW;
  invariant(balance() == 2 * wager && isOutcome(outcome));
  while (outcome == DRAW) {
    commit();
    Alice.only(() => {
      const _fingersAlice = interact.getFingers();
      const _guessAlice = interact.getGuess(_fingersAlice);
      const [_commitAlice, _saltAlice] = makeCommitment(
        interact,
        _fingersAlice
      );
      const commitAlice = declassify(_commitAlice);
      const [_guessCommitAlice, _guessSaltAlice] = makeCommitment(
        interact,
        _guessAlice
      );
      const guessCommitAlice = declassify(_guessCommitAlice);
    });

    Alice.publish(commitAlice).timeout(relativeTime(DEADLINE), () =>
      closeTo(Bob, informTimeout)
    );
    commit();

    Alice.publish(guessCommitAlice).timeout(relativeTime(DEADLINE), () =>
      closeTo(Bob, informTimeout)
    );
    commit();

    unknowable(Bob, Alice(_fingersAlice, _saltAlice));
    unknowable(Bob, Alice(_guessAlice, _guessSaltAlice));

    Bob.only(() => {
      const _fingersBob = interact.getFingers();
      const fingersBob = declassify(_fingersBob);
      const guessBob = declassify(interact.getGuess(_fingersBob));
    });

    Bob.publish(fingersBob).timeout(relativeTime(DEADLINE), () =>
      closeTo(Alice, informTimeout)
    );
    commit();
    Bob.publish(guessBob).timeout(relativeTime(DEADLINE), () =>
      closeTo(Alice, informTimeout)
    );
    commit();

    Alice.only(() => {
      const [saltAlice, fingersAlice] = declassify([_saltAlice, _fingersAlice]);
      const [guessSaltAlice, guessAlice] = declassify([
        _guessSaltAlice,
        _guessAlice,
      ]);
    });
    Alice.publish(saltAlice, fingersAlice).timeout(relativeTime(DEADLINE), () =>
      closeTo(Bob, informTimeout)
    );
    checkCommitment(commitAlice, saltAlice, fingersAlice);
    commit();

    Alice.publish(guessSaltAlice, guessAlice).timeout(
      relativeTime(DEADLINE),
      () => closeTo(Bob, informTimeout)
    );
    checkCommitment(guessCommitAlice, guessSaltAlice, guessAlice);

    commit();

    Alice.only(() => {
      const WinningNumber = fingersAlice + fingersBob;

      interact.seeWinning(WinningNumber);
    });

    Alice.publish(WinningNumber).timeout(relativeTime(DEADLINE), () =>
      closeTo(Alice, informTimeout)
    );

    outcome = winner(fingersAlice, fingersBob, guessAlice, guessBob);
    continue;
  }

  assert(outcome == A_WINS || outcome == B_WINS);
  transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });
});
