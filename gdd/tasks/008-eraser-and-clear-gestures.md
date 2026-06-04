## Source GDD

`gdd/DRAW_AND_GUESS.md#drawing-tools` (Eraser, Clear rows)

## What to build

Two editing gestures for the VR player:

**Eraser**: When the VR controller is flipped upside-down (pitch > ~120° or use controller's up-vector check), the next release of the trigger erases the most recent stroke. Visual feedback: the pen tip changes to an eraser icon or the stroke highlights briefly.

**Clear**: Two-hand grab (both controllers grip simultaneously) then pull hands apart beyond a distance threshold (~0.8m) clears all strokes. A confirmation prompt appears ("Clear all? Yes / No") before executing. The prompt is a simple floating dialog that auto-dismisses if the player doesn't respond within 5 seconds (defaulting to No).

Both gestures are only active during the drawing phase.

HITL because gesture thresholds (upside-down detection angle, pull-apart distance, confirmation UX) need human testing to feel natural.

## Acceptance criteria

- [ ] Flipping controller upside-down activates eraser mode (visual indicator on pen tip)
- [ ] Releasing trigger in eraser mode removes the last stroke
- [ ] Two-hand grip + pull apart shows a "Clear all?" confirmation dialog
- [ ] Selecting "Yes" removes all strokes; "No" / timeout cancels
- [ ] Gestures only work during the drawing phase
- [ ] Thresholds feel natural in a brief VR playtest

## Blocked by

- `002-vr-3d-pen-drawing`
