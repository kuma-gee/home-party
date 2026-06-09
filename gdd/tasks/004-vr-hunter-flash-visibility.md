# 004 — VR Hunter: Movement, Flash Device & Visibility

## Source GDD

`gdd/GHOST_HUNTER.md` → VR Player (Flash Device, Visibility Rule, Wrist Tablet charge count)

## What to build

The VR player becomes the Ghost Hunter: first-person navigation through the house, a Flash Device that emits a cone-shaped bright pulse forward, and the core visibility system that makes ghosts invisible by default.

Flash is the Hunter's primary information tool. Pressing the Flash button fires a bright pulse in a cone ahead of the Hunter. Any ghost caught in that cone becomes visible for 4 seconds. Flash has a 3-second cooldown shown on the Hunter's HUD.

The visibility system is asymmetric: ghosts are invisible to the Hunter unless revealed by Flash. The Hunter appears on the shared-screen map only when within 10 meters of any ghost — giving ghosts directional warning without perfect omniscience.

This is the heart of the cat-and-mouse loop. Slice 002 already has the house, and 003 has ghost movement — this task wires them together so the Hunter can actually hunt.

## Acceptance criteria

- [ ] VR player can walk through the house in first-person (VR locomotion)
- [ ] Flash Device trigger: pressing the assigned VR controller button emits a cone-shaped bright pulse
- [ ] Flash pulse is visually clear — cone of light emanating forward from the Hunter
- [ ] Ghosts within the Flash cone and line-of-sight become visible to the Hunter
- [ ] Revealed ghosts remain visible for 4 seconds, then fade back to invisible
- [ ] Flash has a 3-second cooldown after each use (visual indicator on HUD or wrist)
- [ ] Flash purges haunted objects: if an object is haunted, Flash forces the possessing ghost out (if Haunt system exists — otherwise note as integration point)
- [ ] Ghosts are completely invisible to the Hunter by default (no mesh rendered for VR view)
- [ ] Hunter appears on the shared-screen map when within ~10 meters of any ghost
- [ ] Hunter disappears from the shared-screen map when no ghost is within ~10 meters
- [ ] Hunter icon on shared screen is visually distinct from ghost icons

## Blocked by

- [002-house-environment](./002-house-environment.md) — needs the house to navigate and measure proximity
- [003-ghost-player-movement](./003-ghost-player-movement.md) — needs ghosts to reveal/hide

## Design notes

- The 10m proximity for Hunter detection should be measured in flat 2D distance (XZ plane) from Hunter to nearest ghost, not 3D — avoids vertical exploits
- Ghost visibility toggling: use `visible = false` on ghost meshes for the VR camera layer only, or assign ghosts to a visibility layer the VR camera doesn't render by default
- Flash cone angle: start with ~60° cone, 8m range — tunable later
- Flash cooldown indicator: simple radial fill or icon on the VR HUD
