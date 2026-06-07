## Source GDD

`gdd/DRAW_AND_GUESS.md#skip`

## What to build

A "Skip" button on the VR private HUD panel. The VR player can press it to discard the current word and draw a new one from the pool.

The skip is processed immediately: the current round ends (no scoring), and the next word is pulled. If the last word have been skipped, the game ends

## Acceptance criteria

- [x] Skip button visible on the VR private HUD panel during the drawing phase
- [x] Pressing skip: current round ends immediately, next word drawn
- [x] No points awarded for the skipped round
- [x] If skip is used on the last remaining word, the game ends

## Blocked by

- `004-round-flow-and-word-assignment`
- `009-vr-private-hud-panel`
