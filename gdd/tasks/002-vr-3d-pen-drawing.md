## Source GDD

`gdd/DRAW_AND_GUESS.md#vr-player`, `gdd/DRAW_AND_GUESS.md#drawing-tools` (Pen row)

## What to build

Implement the VR player's primary drawing mechanic: grip + trigger hold continuously spawns 3D line segments in world space. Each stroke is a `RibbonTrailMesh` or `ImmediateMesh` node that grows while the trigger is held and stops when released. Strokes are parented to the world (not to the controller), so they stay in place as the player moves. Lines default to black (expandable to any color later).

The pen controller is a 3D mesh (simple cylinder/cone representing a marker tip) that appears at the VR controller's position when gripping. The trigger acts as the "draw now" signal.

## Acceptance criteria

- [ ] VR player grips + holds trigger → a continuous 3D line follows the controller tip
- [ ] Releasing trigger ends the current stroke
- [ ] Multiple strokes are independent and visible in VR space
- [ ] Strokes persist in world space (they don't follow the controller)
- [ ] Line thickness is comfortable to see (~0.02–0.05 units)
- [ ] Works in the Draw & Guess scene when the drawing phase is active

## Blocked by

- `001-game-scaffold-and-word-submission`
