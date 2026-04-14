# Home Party — Project Guidelines

## Overview

Multiplayer VR party game framework built with Godot 4.6. A VR headset acts as the game server; web browser clients connect as player controllers. The game cycles through a sequence of VR mini-games selected from a menu.

## Architecture

```
Godot Server (VR host)
  ├─ Autoloads: ModLoader, LobbyServer, PlayerManager, HttpServer
  ├─ GameMode — cycles through selected games
  ├─ BaseGame subclasses — individual mini-games (in mods)
  └─ GameClient nodes — one per connected web client

main/ - Core godot part
  └─ everything required for basic game setup

game-client/ - Web Client (Svelte + TypeScript)
  └─ Connects via WebSocket (port 14412) for signaling, then WebRTC for input
  └─ Provide the interface for the players on the phone
```

## Key Autoloads

| Name | File | Purpose |
|------|------|---------|
| `LobbyServer` | `main/utils/lobby_server.gd` | WebSocket signaling server (port 14412); sends `InputLayout` to switch client UI |
| `PlayerManager` | `main/utils/player_manager.gd` | Creates `GameClient` nodes; exposes `PlayerManager.get_players() -> Array[GameClient]` |
| `HttpServer` | `main/utils/http_server.gd` | Serves `build/web/` on port 8484 |
| `ModLoader` | `addons/mod_loader/` | Loads mods from `mods-unpacked/` at startup |

## Game Lifecycle

1. `GameMode.start_games(selected: Array[GameResource])` randomly picks games, instantiates each `BaseGame` scene, and calls `start_game(players, game_setup)`.
2. Game signals `game_finished` when done; `GameMode` calls `get_points()` to accumulate wins.
3. After `num_of_games` rounds, `GameMode` emits `finished`.
4. Games can also emit `game_restart` (replay same game) or `back_to_menu`.

## Input Protocol (WebRTC Data Channel)

Inputs arrive as semicolon-delimited UTF-8 strings over the negotiated data channel (id=1):

| Format | GDScript result | Example |
|--------|----------------|---------|
| `"name;1"` or `"name;0"` | `input_received(name, bool)` | `"jump;1"` |
| `"name;x;y"` | `input_received(name, Vector2)` | `"move;0.5;-0.75"` |

Switch the client UI layout with `LobbyServer.send_layout("joystick")` or `"buttons"`.

## Mini-Game Location

Active VR mini-games live in `mods-unpacked/KumaGee-VRCore/`. Each game needs:
- `<game>.gd` — `extends BaseGame`
- `<game>.tscn` — scene with the script attached
- `<game>.tres` — `GameResource` (name, description, scene, image, tags)

The `GameLoader` discovers games by scanning for `.tres` files that are `GameResource` instances.

## Mod Structure (KumaGee-VRCore)

```
mods-unpacked/KumaGee-VRCore/
  manifest.json          # {"namespace":"KumaGee","name":"VRCore",...}
  mod_main.gd            # extends Node; _init() calls install_script_extensions()
  <game-name>/           # One folder per game
    <game>.gd/.tscn/.tres
```

## Build Commands

```bash
# Game client (run from game-client/)
npm run build            # Build Svelte app → copies output to ../build/web/

# Godot export
# Use the Godot editor: Project → Export → Web → Export Project
# Output: build/web/index.html
```

## Off-Limits Directories

- **`addons/`** — External third-party plugins. Read them to understand their APIs, but **do not modify** unless there is a critical bug with no workaround.
- **`mods-unpacked/KumaGee-Core/`** — Legacy non-VR code from a previous version. Do not use as a reference or modify.
