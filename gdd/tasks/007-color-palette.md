## Source GDD

`gdd/DRAW_AND_GUESS.md#color-palette`, `gdd/DRAW_AND_GUESS.md#drawing-tools` (Color row)

## What to build

Add a grabbable color palette beside the VR player showing 6 colored spheres/swatches: Black (default), Red, Blue, Green, Yellow, White. The VR player points the pen tip into a color to change it. The selected color is used for all subsequent strokes until changed.

The palette is a `pickable.gd` with a mesh and a set of 3D spheres with trigger areas that the pen tip is monitoring for. The current color is indicated by a highlight ring or glow on the selected swatch.

## Acceptance criteria

- [x] Grabbable palette with 6 color swatches appears beside the VR player during drawing phase
- [x] VR player grab and move the palette
- [x] Dipping the pen tip into one of the color changes it; subsequent strokes use the new color
- [x] Current selected color is visually indicated on the palette
- [x] Default color is black

## Blocked by

- `002-vr-3d-pen-drawing`
