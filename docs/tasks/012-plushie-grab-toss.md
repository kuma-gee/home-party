# 012 — VR Advanced Grab & Squeeze

- [ ] Approved by user

## What to build

Building on the grabbable plushie from Slice 1 (011), this slice adds advanced grab interactions: two-handed simultaneous grab, a snap grab point for a "squeeze" feel when picked up, and visual squash/stretch feedback on grab.

The basic single-hand grab, hold, toss, and physics material are already implemented in 011.

**Key design decisions:**
- Enable `second_hand_grab` on the plushie's `XRToolsPickable` for two-handed support
- Add `XRToolsSnapGrabPoint` as an additional grab point for a satisfying "snap to hand" feel
- Plushie squashes/stretches slightly when grabbed and released for toy-like feedback
- Physics feel fine-tuning (drag, gravity while held, stacking stability)

## Acceptance criteria

- [ ] VR player can grab a plushie with both hands simultaneously (second-hand grab mode)
- [ ] Plushie squashes/stretches slightly when grabbed and released (visual feedback)
- [ ] Snap grab point provides a satisfying "snap to hand" feel on pickup
- [ ] Plushies stack stably on top of each other (one plushie can rest on another)
- [ ] Physics feel is fine-tuned — drag while held feels natural, toss velocity is satisfying

## Blocked by

- [011-plushie-spawn-physics](./011-plushie-spawn-physics.md) — provides the grabbable plushie

## Design notes

- Set `second_hand_grab = SecondHandGrab.SWAP` or `SecondHandGrab.SECOND` on the pickable
- `XRToolsSnapGrabPoint` can be added as an extra child node alongside the standard hand grab points
- Squash/stretch can be done via a Tween on the MeshInstance3D scale when `picked_up` / `dropped` signals fire
- Consider using `linear_damp` and `angular_damp` properties while the plushie is held for controllable toss feel
- Stacking stability can be improved by adjusting `contact_monitor`, `contacts_reported`, and collision margins
