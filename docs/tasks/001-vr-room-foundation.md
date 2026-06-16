# 001 — VR Room Foundation

Reference: `docs/HIDE_AND_SEEK.md` — Room Design, VR Player (movement), Shared Screen (room camera)

## What to build

A playable foundation for Hide & Seek: the themed room is loaded in VR, the VR player can move around with smooth locomotion and snap-turn, and the shared TV screen shows a dramatic fixed camera angle of the room. Mobile players can connect and see the shared screen (but don't have game mechanics yet — just a placeholder idle state).

This slice establishes the spatial stage that every subsequent mechanic runs on.

## Acceptance criteria

- [ ] Themed room (e.g., Halloween living room from `assets/hide_seek/halloween/`) is loaded and visible in VR
- [ ] VR player can move freely with left-thumbstick smooth locomotion
- [ ] VR player can snap-turn with right thumbstick
- [ ] VR player collides with walls and furniture (no walking through objects)
- [ ] All eligible props (chairs, tables, pots, etc.) are placed in the room as static bodies
- [ ] Shared screen shows a fixed dramatic camera angle of the room (does not follow VR player)
- [ ] Shared screen shows "0 hiding" badge and a 2:00 placeholder timer
- [ ] Mobile players can connect to the game and see the shared screen (no phone-specific UI yet)
- [ ] No crashes when VR player moves through the full room

## Blocked by

None — can start immediately
