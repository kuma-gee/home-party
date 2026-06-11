# 014 — Plushie States (UNPLAYABLE, DISCONNECTED)

- [ ] Approved by user

## What to build

The plushie now has three visual states that reflect the player's connection and eligibility status:

1. **CONNECTED** (default) — normal colored plushie with player number tag
2. **UNPLAYABLE** — a small icon (e.g., crossed-out gamepad) floats above the plushie indicating the player cannot join the currently selected game (e.g., they're using a gamepad but the game is phone-only). Plushie color remains normal.
3. **DISCONNECTED** — the plushie material desaturates to gray, the player number tag changes to a disconnect icon (e.g., Wi-Fi symbol with X). The plushie retains full physics — the VR player can still pick it up and toss it. If the player reconnects, the plushie restores to CONNECTED state.

**State triggers:**
- CONNECTED ↔ DISCONNECTED: driven by `ClientController.active` (false on `reset()`, true on `initialize()`)
- UNPLAYABLE: triggered by a new signal/query from `GameSettings` or `GameResource` — when a game is selected that doesn't support the player's controller type. The state toggles when game selection changes.

**Key design decisions:**
- DISCONNECTED uses a material override — swap to a grayscale version of the plushie material
- UNPLAYABLE shows a `Sprite3D` or `Label3D` icon floating above the plushie (billboarded, always faces VR player)
- The disconnect icon replaces the player number text in the tag Label3D
- Physics is never disabled — the VR player experience is uninterrupted regardless of state
- Reconnection restores: tween the material back from gray to color (nice visual transition)

## Acceptance criteria

- [ ] Plushie defaults to CONNECTED state with normal color and player number tag
- [ ] When a player disconnects (phone closes browser, network drops), plushie turns gray within 1 second
- [ ] Player number tag changes to a disconnect icon (e.g., "!" or "X" symbol) in DISCONNECTED state
- [ ] Gray plushie is still fully physics-enabled — VR player can pick up, toss, and stack it
- [ ] When a disconnected player reconnects, the plushie restores to full color and normal tag
- [ ] UNPLAYABLE state shows a small icon (crossed-out gamepad/phone) floating above the plushie
- [ ] UNPLAYABLE icon updates when a different game is selected (clear and re-evaluate)
- [ ] State transitions are smooth — material desaturation tweens over ~0.3s rather than snapping

## Blocked by

- [011-plushie-spawn-physics](./011-plushie-spawn-physics.md) — needs a plushie in the scene to change state

## Design notes

- Material grayscale: easiest approach is a `ShaderMaterial` with a grayscale toggle uniform, or swap between two material instances (colored / grayscale)
- For disconnect detection: listen to `ClientController.active_changed` signal — `active == false` means disconnected
- For UNPLAYABLE: the `GameSelectZone` or `menu_world.gd` can emit a signal when game selection changes → plushie queries whether the selected game supports this controller type
- UNPLAYABLE icon: `Sprite3D` with a `SubViewport` rendering a simple icon, or a `Label3D` with an emoji/unicode symbol like "🚫"
- Player reconnection: `PlayerManager.create_peer` calls `player.initialize()` which sets `active = true` — the plushie should listen for this on its existing reference
- Store a reference to the `ClientController` on each plushie instance to monitor state changes
