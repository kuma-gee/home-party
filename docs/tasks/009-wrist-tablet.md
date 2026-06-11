# 009 — Wrist Tablet

- [ ] Approved by user

## What to build

The Wrist Tablet is the Hunter's information hub — a diegetic screen mounted on the VR player's wrist. It displays a top-down map of the house with three layers of information:

1. **Task markers** — the same mischief task locations ghosts are trying to complete. This lets the Hunter patrol and intercept.
2. **Ghost interaction pings** — when ghosts use abilities (Phase Walk ripples, Haunt triggers), a ping appears on the map at that location and fades over time. Gives the Hunter leads to investigate.
3. **Flash charge count** — how many Flash uses are available (or cooldown remaining).

The tablet is glanceable — the Hunter can look down at their wrist during gameplay to read the map without pausing.

## Acceptance criteria

- [ ] Wrist Tablet is attached to the VR player's left wrist (visible in first-person)
- [ ] Tablet shows a simplified top-down map of the house (rooms, walls, doors outlined)
- [ ] Task markers appear on the tablet map in the same positions as the shared-screen map
- [ ] Completed tasks are removed or grayed out on the tablet
- [ ] Ghost interaction pings appear on the map when ghosts use abilities (Phase Walk, haunt trigger)
- [ ] Pings show as brief glowing dots at the location and fade over ~10 seconds
- [ ] Flash charge count is visible on the tablet (numeric or icon-based)
- [ ] Flash cooldown indicator is visible on the tablet (radial fill or bar)
- [ ] Tablet does not show ghost positions directly (Hunter must deduce from pings and tasks)
- [ ] Tablet is readable at arm's length in VR (text/icons sized appropriately)

## Blocked by

- [004-vr-hunter-flash-visibility](./004-vr-hunter-flash-visibility.md) — needs Flash cooldown state to display
- [007-mischief-tasks](./007-mischief-tasks.md) — needs task data to display on map

## Design notes

- Use a `SubViewport` rendering to a texture on the tablet mesh for the map — same approach as Castle Defense's gate HP viewport
- Keep the map minimal: rooms as rectangles, walls as lines, markers as dots. Too much detail is unreadable at wrist-scale
- Ghost interaction pings: tasks 005 (Phase Walk) and 006 (Haunt) should emit events that the tablet listens to
- The tablet should be a separate scene that can be instanced onto the XR player rig
- Map orientation: consider whether the map is north-locked or rotates with the player — north-locked is simpler and lets the Hunter learn the layout
