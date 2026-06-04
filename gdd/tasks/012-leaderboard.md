## Source GDD

`gdd/DRAW_AND_GUESS.md#leaderboard`, `gdd/DRAW_AND_GUESS.md#game-end`

## What to build

After all words have been drawn (or the VR player disconnects), display a ranked leaderboard on both the shared desktop screen and in VR space.

The leaderboard shows:
- Ranked list of all players (including the VR player) by total score
- Each player's total points + number of rounds they guessed correctly
- The winner is highlighted with a celebratory animation (gold glow, particle burst, or text emphasis)

Uses the existing patterns for game-over screens: `xr_player.gameover(message)` for VR and `show_screen(scene)` for the shared screen. Reuse or extend the desktop gameover scene (`main/ui/`) or create a Draw & Guess specific version.

## Acceptance criteria

- [ ] Leaderboard appears on the shared screen after all words are drawn
- [ ] Leaderboard appears in VR space (floating panel)
- [ ] All players ranked by total score (highest first)
- [ ] Each entry shows total points + rounds guessed correctly
- [ ] Winner is visually highlighted (gold/glow animation)
- [ ] Leaderboard persists until VR player exits or starts a new game

## Blocked by

- `006-scoring-system`
