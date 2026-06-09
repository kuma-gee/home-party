# 001 — Game Scaffold

## Source GDD

`gdd/GHOST_HUNTER.md` — all sections (structural foundation)

## What to build

Create the Ghost Hunter game registration and main scene skeleton. This gives the game a place to live in the project: it appears on the game shelf, can be launched, and has the standard lifecycle hooks (prepare → start → gameover) wired up. No gameplay yet — just the structural bones that every other task plugs into.

The main scene extends `XRToolsSceneBase` and follows the same conventions as Castle Defense and Draw & Guess. It includes a prepare UI with player list (using a `JoinedPlayer` subclass), ready-check flow, and a placeholder gameover that returns to the hub.

## Acceptance criteria

- [ ] `GameResource` `.tres` file exists in `mods-unpacked/KumaGee-VRCore/ghost-hunter/`
- [ ] Game appears on the VR game shelf and shows its name, description, and player count
- [ ] Launching the game loads the main scene
- [ ] Prepare UI is shown on game start — player list displays connected players with their assigned colors
- [ ] Each player gets a `JoinedPlayer` subclass UI node (placeholder ghost UI)
- [ ] Ready check works: game transitions from prepare to start when VR player confirms
- [ ] Placeholder gameover flow: calling finish ends the round and returns to hub
- [ ] Scene root extends `XRToolsSceneBase` (`xr_player` reference available)
- [ ] `PlayerManager.playing_clients` is populated on game start for game code to iterate

## Blocked by

None — can start immediately
