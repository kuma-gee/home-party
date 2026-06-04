## Source GDD

`gdd/DRAW_AND_GUESS.md#shared-desktop-screen`

## What to build

An overlay on the shared desktop screen (the TV quad mesh via `vr_screen` / `XRToolsViewport2DIn3D`) that displays game state for all spectators and mobile players watching the screen.

The HUD shows:
- **Scoreboard**: list of all players with current scores, sorted by rank
- **Round timer**: prominent countdown (large numbers, turns red under 10s)
- **Guess progress**: "3/6 guessed" — updates live as players guess correctly
- **Word progress**: "Word 3 of 7"
- **Winner alerts**: toast-style popup when someone guesses correctly: "Alice — 1st!" (with rank)

Uses the existing `vr_space.gd:56` `show_screen(scene)` pattern to instantiate a 2D scene into the desktop viewport.

## Acceptance criteria

- [ ] Shared screen shows a scoreboard sorted by total score, updating live each round
- [ ] Large countdown timer visible on the shared screen (turns red under 10s)
- [ ] Guess progress updates in real-time as players guess correctly
- [ ] Word progress indicator (e.g., "Word 3 of 7")
- [ ] Winner alerts pop up on correct guess showing name and rank ("Alice — 1st!")
- [ ] HUD elements are visually clear and readable on a 16:9 screen

## Blocked by

- `005-mobile-guess-submission-and-feedback`
- `006-scoring-system`
