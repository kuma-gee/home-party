# 003 — Tag System

Reference: `docs/HIDE_AND_SEEK.md` — Tagging (Grab + Trigger), Wrong tag (2s stun), Correct tag (celebration)

## What to build

The two-step tagging mechanic: grip to grab a prop, then trigger to "tag" it. The system tracks two prop states — **static** (normal room prop) and **hider** (a prop controlled by a mobile player). Tagging a static prop triggers the wrong-tag response: the prop is dropped, the VR player is stunned for 2 seconds (can't grab or tag). Tagging a hider prop triggers the correct-tag response: celebration burst, prop opens/reveals, hider is marked as found.

To keep this slice independently testable, a developer debug flag allows marking any prop as a "simulated hider" so the correct-tag path can be verified before mobile players exist.

The tag state machine, the stun timer, the celebration VFX, and the prop state system are all built here.

## Acceptance criteria

- [ ] VR player grabs a prop → grip holds it (reuses 002 interaction)
- [ ] VR player pulls trigger while holding → "tag" event fires
- [ ] Tagging a static prop → 2s stun: prop drops, VR hand can't grab or tag, visual indicator (screen flash / controller vibration)
- [ ] After 2s stun → VR hand returns to normal, can grab again
- [ ] Tagging a dev-flagged "hider" prop → celebration effect (prop bursts open, particles, sound)
- [ ] Tagging a "hider" prop → prop is marked as "found" and disabled (removed from world)
- [ ] Tagging a "hider" prop → VR player is NOT stunned (correct tag is a reward)
- [ ] Shared screen shows "Found" feed entry when a hider is tagged (e.g., "Player found!" placeholder)
- [ ] Cannot tag without first grabbing (no ranged tagging)
- [ ] Cannot grab during stun

## Blocked by

- 002 — VR Prop Interaction
