# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

VR party game (Godot 4.6, OpenXR). One player wears a headset; 2–8 phone players join as web controllers. Mini-games are modular and discovered at runtime from `mods-unpacked/`.

## Commands

**Web client (phone controller UI):**
```bash
cd game-client
npm run dev    # dev server at localhost:8080
npm run build  # outputs to ../build/web/ (served by Godot's HttpServer)
```
After editing `game-client/`, run `npm run build` so the Godot HTTP server serves the updated files.

**Type checking:**
```bash
cd game-client && npx svelte-check
```

**Godot:** Open project in Godot editor and run/export. No CLI build scripts.

## Architecture

### Autoloaded Singletons
- `LobbyServer` — WebSocket signaling server (port 14412). Manages peer lifecycle, routes JSON messages, broadcasts input layouts.
- `PlayerManager` — Creates/destroys `GameClient` nodes per connected phone player.
- `HttpServer` — Serves `build/web/` (port 8484) for phone browser connections.
- `AudioManager`, `XRToolsUserSettings`, `XRToolsRumbleManager`, `ModLoader`, `ModLoaderStore`

### Mini-Game System
- Games are `GameResource` (`.tres`) files discovered by `GameLoader` scanning `mods-unpacked/`.
- Each game's scene extends `XRToolsSceneBase`.
- `GameShelve` renders a 3D carousel in the VR menu for selection.
- `GameResource` fields: `name`, `description`, `scene` (PackedScene), `image` (Texture2D), `tags` (Array[String]), min/max player counts.

### Networking (Godot ↔ Phone)
```
Phone browser → WebSocket (port 14412) → LobbyServer signals → PlayerManager
                                        → WebRTC data channel "inputs" (id 1)
```
- Players keyed by persistent UUID (`client_id` from `localStorage`), not by transient `peer_id`.
- `LobbyServer.players` = `Dictionary[String, Dictionary]` (UUID → data)
- `LobbyServer.peer_to_uuid` = `Dictionary[int, String]`
- Input layout broadcast: `LobbyServer.send_layout("joystick")` or `LobbyServer.send_layout("buttons")`

### Input Protocol (WebRTC data channel, plain strings)
- Button: `"name;1"` or `"name;0"`
- Vector/joystick: `"name;x;y"`
- Built-in names: `"move"`, `"action"`, `"secondary"`
- Read in games via `GameClient.input_received` signal; use `GameClient.get_move()` for current movement vector.

### Web Client (`game-client/`)
- SvelteKit app, SSR disabled. Entry: `src/routes/+page.svelte`.
- Networking: `src/lib/websocket.ts` (signaling) + `src/lib/webrtc.ts` (data channel).
- State: `src/lib/store.ts` (Svelte stores).
- `src/game/` and `src/PhaserGame.svelte` are dead Phaser template code — do not use.

### VR Interactions (godot-xr-tools)

Key node types:
| Node | Purpose |
|------|---------|
| `XRToolsPickable` | Rigidbody grabbable by hands |
| `XRToolsInteractableAreaButton` | 3D area button; emits `button_pressed` |
| `XRToolsFunctionPickup` | Hand controller grab logic |

Physics layer shortcuts (bit indices, 0-based):
| Layer # | Name |
|---------|------|
| 1 | Static World |
| 2 | Dynamic World |
| 18 | Player Hands |
| 20 | Player Body |
| 21 | Pointable Objects |
| 23 | UI Objects |

### UI in 3D Space
Floating panels use `Sprite3D + SubViewport`. Set `SubViewport.render_target_update_mode = ALWAYS`.

Reusable UI components:
- `main/ui/joined_player.tscn` — player card (colored circle + icon + name)
- `main/ui/player_list.gd` — dynamic player roster with color assignment; `PlayerList.COLORS` = 8-color palette
- `main/ui/material_icon.gd` — Material Symbols font icon renderer
- `main/utils/circle_timer.gd` — shader-based ring countdown (0.0–1.0 fill param)

CSS theme conventions (`theme.css`): `PanelContainer` root (bg `#111111`, `border-radius: 12px`), `MarginContainer` wrap (16px), `VBoxContainer`/`HBoxContainer` contents (8px separation), `Label.Large` = 48px + 16px outline.

### VFX Library (`mods-unpacked/KumaGee-VRCore/vfx/`)
Reuse before building: `impact.tscn`, `explosion_vfx.tscn`, `spark.tscn`, `smoke.tscn`, `muzzle.tscn`, `projectile.tscn`. Use `PlayParticleSystems.gd` for multi-layer batch effects; `particle_callback.gd` for chaining.

### Mod System
Built on `godot-mod-loader` (v6.2.0+). Each mod in `mods-unpacked/<Author-Name>/` has `manifest.json` and a `mod_main.gd` entry point.

## GDScript Conventions

**Logging — always `KumaLog`, never `print`:**
```gdscript
var logger = KumaLog.new("MyGame")
logger.info("Started with %d players" % players.size())
logger.debug("Player dir: %s" % str(dir))
logger.error("Something broke")
```

**Mini-game setup pattern:**
```gdscript
extends XRToolsSceneBase

func scene_loaded(game_clients: Array[GameClient]) -> void:
    for client in game_clients:
        client.input_received.connect(_on_input.bind(client))
```

**Pausing:** Games run under `PROCESS_MODE_PAUSABLE`. Use `get_tree().paused = true/false`.

**VR button wiring:**
```gdscript
@export var my_button: XRToolsInteractableAreaButton

func _ready() -> void:
    my_button.button_pressed.connect(_on_button_pressed)
```

**Registering a new mini-game:** Create a `GameResource` `.tres` in the mod folder; `GameLoader` discovers it automatically. Required fields: `name`, `description`, `scene`, `image`, `tags`.

**Networking changes:** Any change to the WebSocket/WebRTC wire protocol requires matching changes in `game-client/`.
