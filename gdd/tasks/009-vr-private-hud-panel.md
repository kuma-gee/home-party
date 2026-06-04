## Source GDD

`gdd/DRAW_AND_GUESS.md#word-display`

## What to build

A floating panel visible only to the VR player (positioned above the palette or at eye level, ~1m in front, off to the side). Uses a `SubViewport` with a `Control` node rendered as a `ViewportTexture` on a `QuadMesh`.

The panel displays:
- The current word (large, bold text — this is the private reveal)
- Round timer countdown (prominent, large font, changes color under 10s)
- Current scores of all players (small, bottom corner, scrollable if many players)
- Word progress (e.g., "Word 3 of 7")

The panel fades in at the start of each drawing phase and fades out during the reveal period between rounds.

## Acceptance criteria

- [ ] Private floating panel appears in VR during the drawing phase, centered in the player's peripheral view
- [ ] Shows the current word in large text (only VR player can see it)
- [ ] Shows countdown timer that updates every frame
- [ ] Shows all player scores compactly at the bottom
- [ ] Shows word progress (e.g., "Word 3 of 7")
- [ ] Timer text turns red/urgent when < 10 seconds remain
- [ ] Panel fades in/out at phase transitions

## Blocked by

- `004-round-flow-and-word-assignment`
