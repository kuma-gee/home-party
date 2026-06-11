# 013 — Player Button → Squeak & Glow Feedback

- [ ] Approved by user

## What to build

When a mobile player presses the A button (or any button) on their phone, their corresponding plushie in the VR living room reacts with an audio + visual cue:
- A squeak/toy sound effect plays (soft, cute — like a dog toy or rubber duck)
- The plushie glows briefly — its material emissive ramps up and fades back down

The system hooks into the existing `ClientController.primary_action_pressed` signal. Each plushie knows which `ClientController` it belongs to, so only the correct plushie reacts. The squeak sound is spatial (attached to the plushie's position in 3D space). The glow is a brief emissive flash on the plushie mesh, driven by a `Tween`.

This slice uses placeholder animal meshes (same sphere/capsule from Slice 1) — the squeak+glow is independent of visual fidelity.

**Key design decisions:**
- Each plushie instance connects to its owning player's `primary_action_pressed` signal
- Sound plays via `AudioStreamPlayer3D` child on the plushie scene — spatial audio so VR player hears it from where the plushie is
- Glow is a material `emission_energy_multiplier` tween: 0 → 1 → 0 over ~0.5s
- The squeak audio clips are short (< 1s), cute toy-like sounds stored in `assets/sound/plushie/`
- `secondary_action_pressed` could produce a different sound/pitch for variety

## Acceptance criteria

- [ ] Pressing the A button on the phone triggers a squeak sound from the plushie in 3D space
- [ ] The squeak sound is spatial — VR player hears it from the plushie's location
- [ ] The plushie glows briefly (emissive flash) when the button is pressed
- [ ] Only the correct player's plushie reacts — no cross-talk between players
- [ ] The glow animation is smooth (tweened: ramp up ~0.15s, fade ~0.35s)
- [ ] Multiple players pressing buttons simultaneously all play independently
- [ ] Sound effect is a short cute squeak (< 1s), not annoying on repeat presses
- [ ] Works with the existing `ClientController.primary_action_pressed` signal (already wired for A button on phone)

## Blocked by

- [011-plushie-spawn-physics](./011-plushie-spawn-physics.md) — needs a plushie in the scene to react

## Design notes

- Apply the emissive glow via a `ShaderMaterial` or `StandardMaterial3D` with `emission_enabled = true` — tween `emission_energy_multiplier`
- Use `AudioManager` or direct `AudioStreamPlayer3D` for the squeak — the choice depends on whether you want centralized audio pooling
- Add `plushie_squeak_01.wav` etc. to `assets/sound/plushie/` — small, cute, no annoying harmonics
- For secondary action (B button), consider a different pitch or a "boing" sound
- The plushie script should store a reference to its `client_controller` to connect/disconnect signals
