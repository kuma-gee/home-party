## Source GDD

`gdd/DRAW_AND_GUESS.md#edge-cases` (VR disconnects, Mobile disconnects)

## What to build

Handle disconnections gracefully:

**VR player disconnects**: The current game ends immediately. Current round scores are finalized (no further guesses accepted). Leaderboard is shown on the shared screen with whatever scores exist.

**Mobile player disconnects**: Their submitted word remains in the word pool (it was already contributed). They cannot rejoin the game — if their UUID reconnects, treat them as a new spectator (no re-entry to game state). The round continues unaffected.

**Edge case — only 2 players (1 VR + 1 mobile)**: The game is functional but displays a "recommend 3+ players" notice on the shared screen at game start. All mechanics work with a single guesser.

## Acceptance criteria

- [ ] VR disconnection immediately ends the game and shows the leaderboard with current scores
- [ ] Mobile disconnection mid-game: their word stays in pool, they cannot rejoin
- [ ] Mobile disconnection pre-game: their submitted word is still accepted
- [ ] 2-player mode works: VR draws, 1 mobile guesses — all mechanics functional
- [ ] A "recommend 3+ players" notice appears on the shared screen when < 3 mobile players

## Blocked by

- `004-round-flow-and-word-assignment`
- `012-leaderboard`
