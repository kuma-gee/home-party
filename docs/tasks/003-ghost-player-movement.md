# 003 — Ghost Player Movement & Phone Controls

- [ ] Approved by user

## What to build

Phone players control ghosts on the shared screen. Each connected mobile player gets a colored ghost character that moves around the house from a top-down perspective. The phone sends joystick movement + A/B button presses via the existing WebRTC data channel protocol. The ghost `JoinedPlayer` UI shows in the player list with the player's assigned color.

At this stage ghosts can move and press buttons — Phase Walk and Haunt behaviors are separate tasks. The goal here is to prove the dual-runtime control loop: phone input → ghost movement on shared screen.

## Acceptance criteria

- [ ] Each connected mobile player spawns a ghost on the shared screen with a unique color
- [ ] Phone left joystick moves the ghost in the top-down house view (directional movement)
- [ ] Ghost movement respects house walls and room boundaries
- [ ] Phone A button triggers a registered input in the ghost controller (action fired signal)
- [ ] Phone B button triggers a registered input in the ghost controller (secondary fired signal)
- [ ] Multiple ghosts (2+) can move independently without input crosstalk
- [ ] Ghost `JoinedPlayer` subclass UI appears in the player list with the player's name and color
- [ ] Ghosts are visible to each other on the shared screen at all times

## Blocked by

- [001-game-scaffold](./001-game-scaffold.md) — needs the scene, prepare UI, and player list

## Design notes

- Use the existing `LobbyServer.send_layout("joystick")` to configure phone controls — no custom layout needed
- Ghosts are 3D characters viewed from the top-down camera; use simple colored capsules or spheres initially
- Ghost names on the shared screen should match the player's name from `PlayerManager`
- Ghost color should match the color assigned by `PlayerList` (same 8-color palette)
