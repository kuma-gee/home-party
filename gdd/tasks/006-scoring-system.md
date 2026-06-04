## Source GDD

`gdd/DRAW_AND_GUESS.md#mobile-scoring`, `gdd/DRAW_AND_GUESS.md#vr-scoring`, `gdd/DRAW_AND_GUESS.md#speed-bonus`

## What to build

Implement the scoring formulas for both mobile and VR players. Accumulate scores across all rounds; track per-player totals.

**Mobile scoring** (per round based on guess arrival order):
- 1st correct guess = 5 pts
- 2nd = 4, 3rd = 3, 4th = 2, 5th+ = 1
- Only the first correct guess per player per round counts

**VR scoring** (per round, based on how many players guessed correctly):
- All players = 5, 75%+ = 4, 50-74% = 3, 25-49% = 2, 1-24% = 1, none = 0
- Speed bonus: +1 if first guess arrives under 15 seconds into the timer

**Tracked per player**: total points, number of rounds guessed correctly.

Reuse or extend `StatsManager` (`main/utils/stats_manager.gd`) or create a new scoring autoload for Draw & Guess. Scores persist across rounds and are fed into the leaderboard (012).

## Acceptance criteria

- [ ] Mobile players earn points by guess order per round (5/4/3/2/1)
- [ ] VR player earns points based on % of players who guessed correctly that round
- [ ] VR player gets +1 speed bonus if first guess is under 15 seconds
- [ ] Accumulated scores persist across all rounds
- [ ] Per-player stats (total points, rounds guessed) are queryable for the leaderboard

## Blocked by

- `005-mobile-guess-submission-and-feedback`
