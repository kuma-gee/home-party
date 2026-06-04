## Source GDD

`gdd/DRAW_AND_GUESS.md#color-palette`, `gdd/DRAW_AND_GUESS.md#drawing-tools` (Color row)

## What to build

Add a floating color palette beside the VR player showing 6 colored spheres/swatches: Black (default), Red, Blue, Green, Yellow, White. The palette orbits at a comfortable distance (roughly at hip height, ~0.6m from the player's non-dominant side). The VR player points at a color and grips to select. The selected color is used for all subsequent strokes until changed.

The palette is a `SubViewport` on a `Sprite3D` or a set of 3D spheres with trigger areas (see `addons/godot-xr-tools/` for area interaction patterns). The current color is indicated by a highlight ring or glow on the selected swatch.

## Acceptance criteria

- [ ] Floating palette with 6 color swatches appears beside the VR player during drawing phase
- [ ] VR player can look at and point at a color swatch
- [ ] Grip selects that color; subsequent strokes use the new color
- [ ] Current selected color is visually indicated on the palette
- [ ] Default color is black
- [ ] Palette does not obstruct the drawing area (positioned to the side)

## Blocked by

- `002-vr-3d-pen-drawing`
