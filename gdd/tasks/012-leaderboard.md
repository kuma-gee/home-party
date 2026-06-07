## Source GDD

`gdd/DRAW_AND_GUESS.md#leaderboard`, `gdd/DRAW_AND_GUESS.md#game-end`

## What to build

After all words have been drawn, display a ranked leaderboard on both the shared desktop screen and in VR space.

The leaderboard shows:
- Ranked list of all players (including the VR player) by total score
- Each player's total points + number of rounds they guessed correctly
- The winner is highlighted with a celebratory animation (gold glow, particle burst, or text emphasis)

Create a shared scene that can be used in the VR screen and desktop screen.

## Acceptance criteria

- [x] Leaderboard appears on the shared screen after all words are drawn
- [x] Leaderboard appears in VR space (floating panel)
- [x] All players ranked by total score (highest first)
- [x] Each entry shows total points + rounds guessed correctly
- [x] Winner is visually highlighted (gold/glow animation)
- [x] Leaderboard persists until VR player exits or starts a new game

## Blocked by

- `006-scoring-system`
