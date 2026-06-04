## Source GDD

`gdd/DRAW_AND_GUESS.md#skip`

## What to build

A "Skip" button on the VR private HUD panel. Once per game, the VR player can press it to discard the current word and draw a new one from the pool. The skipped word is returned to the end of the pool for potential reuse. After use, the skip button is visually grayed out or hidden for the remainder of the game.

The skip is processed immediately: the current round ends (no scoring), and the next word is pulled. If all words have been skipped, the last available word is used.

## Acceptance criteria

- [ ] Skip button visible on the VR private HUD panel during the drawing phase
- [ ] Pressing skip: current round ends immediately, word returns to pool, next word drawn
- [ ] Skip can only be used once per game; button disappears/hides after use
- [ ] No points awarded for the skipped round
- [ ] If skip is used on the last remaining word, the game ends

## Blocked by

- `004-round-flow-and-word-assignment`
- `009-vr-private-hud-panel`
