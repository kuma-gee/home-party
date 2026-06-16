# 004 — Mobile Hider

Reference: `docs/HIDE_AND_SEEK.md` — Mobile Players (Setup, Controls, Prop selection), Shared Screen (hider count), VR Player (held prop blocks movement)

## What to build

The mobile player experience end-to-end: connecting as a hider, picking a prop during setup, moving as that prop during the hunt, and being found by the VR player.

During the **setup phase** (8s), the mobile player sees the room top-down on their phone with surrounding props highlighted. They hold button A to highlight the nearest prop, release to transform into it.

During the **hunt phase**, the mobile player moves their prop with the left joystick. When the VR player grabs their prop, the mobile player's movement is locked (they're "held"). When the VR player triggers a tag on their prop, the found sequence from 003 plays out. The mobile player sees a "You've been found!" screen.

The shared screen hider count updates as players are found. The mobile phone layout (joystick + A/B buttons) is sent to connected phones.

## Acceptance criteria

- [ ] Mobile player connects and enters the game lobby
- [ ] Phone displays the custom "hide-and-seek" input layout (joystick + A/B buttons)
- [ ] Setup phase: phone shows a top-down view of the room with prop positions
- [ ] Setup phase: holding button A highlights the nearest eligible prop on the phone
- [ ] Setup phase: releasing button A transforms the player into that prop (original static prop disappears, mobile now controls it)
- [ ] Setup phase: mobile player can move around while holding A to change which prop is highlighted
- [ ] Hunt phase: mobile player moves their prop with the left joystick
- [ ] VR player sees the mobile player's prop moving in the room
- [ ] VR player grabs the mobile player's prop → mobile player's movement is locked (cannot move)
- [ ] VR player tags the mobile player's prop (correct tag from 003) → "Found!" celebration plays
- [ ] Mobile player sees a "You've been found!" screen with their stats
- [ ] Shared screen hider count decrements when a player is found (e.g., "3 hiding" → "2 hiding")
- [ ] Static props that were not chosen remain in place and function normally (wrong tag = stun)
- [ ] Multiple mobile players can hide simultaneously (up to 7)

## Blocked by

- 001 — VR Room Foundation
- 003 — Tag System
