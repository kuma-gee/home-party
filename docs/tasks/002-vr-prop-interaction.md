# 002 — VR Prop Interaction

Reference: `docs/HIDE_AND_SEEK.md` — VR Player (interaction), Controls (grip, release/throw)

## What to build

The VR player can physically interact with props in the room: grip to grab, release to throw, and inspect objects freely. Every prop in the room is an `XRToolsPickable` rigid body with physics. This is the tactile, physical core of the VR experience — the joy of rummaging through the room.

No tagging yet — just grab, hold, move, and release.

## Acceptance criteria

- [ ] Every eligible prop (chair, vase, pumpkin, etc.) is a grabbable rigid body
- [ ] VR player grips a prop → prop attaches to hand, follows movement
- [ ] VR player releases grip → prop drops with physics (falls, bounces, collides)
- [ ] VR player flings wrist while releasing → prop is thrown with momentum
- [ ] Props collide with each other and the environment (stacking, knocking over)
- [ ] VR hand visually aligns with the grabbed prop (no floating offsets)
- [ ] Props return to a reset position when the round resets (no lost props)
- [ ] Performance remains stable with all props as physics bodies (no jitter, no frame drops)

## Blocked by

- 001 — VR Room Foundation
