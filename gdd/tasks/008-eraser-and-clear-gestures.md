## Source GDD

`gdd/DRAW_AND_GUESS.md#drawing-tools` (Eraser, Clear rows)

## What to build

Two editing tools for the VR player, accessible during the drawing phase:

**Eraser**: A pickable object (like the pen) that the VR player can grab. When the trigger is held down and the eraser tip is near a stroke, that stroke is erased. The eraser glows red when actively erasing, and returns to a neutral gray when idle. Each trigger press erases one stroke (re-press to erase another).

**Clear**: A red-tinted swatch/button on the color palette. Touching it with the pen tip shows a "Clear all strokes?" confirmation dialog in VR. The dialog has Yes/No buttons and auto-dismisses after 5 seconds (defaults to No). Selecting Yes removes all strokes from the scene.

Both tools are only active during the drawing phase.

HITL because eraser proximity threshold and confirmation dialog positioning/scale need human testing to feel natural.

## Acceptance criteria

- [ ] Eraser tool is a pickable object grabbable in VR (spawned alongside pen and palette)
- [ ] Holding trigger while eraser tip is near a stroke erases that stroke (one per trigger press)
- [ ] Eraser mesh glows red when actively erasing, neutral gray when idle
- [ ] Touching the Clear swatch on the palette with the pen tip shows a confirmation dialog
- [ ] Selecting "Yes" removes all strokes; "No" / 5s timeout cancels
- [ ] Both tools only work during the drawing phase

## Blocked by

- `002-vr-3d-pen-drawing`
