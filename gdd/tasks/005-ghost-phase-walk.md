# 005 — Ghost Phase Walk

## Source GDD

`gdd/GHOST_HUNTER.md` → Ghost Players → Phase Walk

## What to build

Ghosts gain the ability to Phase Walk — pass through walls. When activated, the ghost can move through wall geometry but at reduced speed. While inside a wall, the ghost leaves a faint shimmer trail that an observant Hunter might spot. A 3-second cooldown applies after each use.

Passing through a wall creates a brief visual ripple on the shared screen, visible to all other ghosts. This gives teammates situational awareness without revealing the ghost's exact position to the Hunter.

Phase Walk cannot end while the ghost is still inside a wall — the ghost must reach open space before the ability disengages (or is auto-pushed to the nearest valid position).

## Acceptance criteria

- [ ] Ghost can activate Phase Walk (assigned button — recommend secondary/B for discoverability next to A/Haunt)
- [ ] While Phase Walk is active, ghost passes through all wall collision
- [ ] Ghost movement speed reduced while inside a wall (tunable: start with 50% reduction)
- [ ] Faint shimmer trail renders behind the ghost while phasing (visible in both top-down and potentially VR views)
- [ ] Wall-passing creates a brief visual ripple/vfx on the shared screen at the entry/exit point
- [ ] Ripple is visible to all ghosts on the shared screen
- [ ] 3-second cooldown after Phase Walk ends before it can be used again
- [ ] Cooldown indicator visible to the ghost on the shared screen (e.g., ability icon with fill)
- [ ] Ghost cannot end Phase Walk while inside wall geometry — must exit to open space first
- [ ] If ghost is stuck inside a wall when ability times out, ghost is pushed to nearest open space

## Blocked by

- [003-ghost-player-movement](./003-ghost-player-movement.md) — needs ghost movement and input system

## Design notes

- Phase Walk could be a timed ability (e.g., 2 seconds of phasing per activation) or a toggle — toggle is simpler and matches GDD intent
- Shimmer trail: a semi-transparent ribbon or particle trail following the ghost's path during phasing
- The ripple VFX is a shared-screen-only visual — does not need to appear in VR (Hunter already can't see ghosts)
- Wall detection: use Godot physics layers — walls on one layer, normal movement collides with it, Phase Walk temporarily disables that collision mask
