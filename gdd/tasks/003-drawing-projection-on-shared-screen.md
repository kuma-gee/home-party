## Source GDD

`gdd/DRAW_AND_GUESS.md#drawing-phase`, `gdd/DRAW_AND_GUESS.md#shared-desktop-screen` (Live drawing)

## What to build

Ensure 3D strokes drawn by the VR player are visible in real-time on the shared desktop screen (the in-room TV quad mesh via existing `VRSpace` / `SubViewport` + `CameraFollow3D` architecture). The spectator camera should track the VR player's yaw so the drawing stays roughly centered on screen. If the default `CameraFollow3D` angle doesn't show the drawing well, adjust the curve or offset so the drawing area is clearly visible.

This slice is tagged HITL because camera positioning needs a human to judge whether the drawing is legible on the TV. The developer should deploy to VR, draw a few shapes, and look at the shared screen to confirm.

## Acceptance criteria

- [x] 3D strokes appear on the shared desktop TV quad mesh in real-time as they are drawn
- [x] Spectator camera roughly follows the VR player's yaw so strokes don't drift off-screen
- [x] Angles are comfortable for spectators to read the drawing (not too close, not too far)
- [x] No additional capture or projection code needed beyond the existing VRSpace setup

## Blocked by

- `002-vr-3d-pen-drawing`
