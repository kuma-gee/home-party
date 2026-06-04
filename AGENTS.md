# AGENTS.md

## Project Structure

**Dual-runtime VR game:** Godot 4.6 VR game + SvelteKit smartphone controller (WebRTC connected)

- `main/` - Core VR game
  - `ui/` - HUD: score table, player list, gameover screen, time bar, QR code display
  - `utils/` - All autoloads (singletons): HttpServer, LobbyServer, PlayerManager, StatsManager, BGMManager, GameSettings, AudioManager
  - `vr/` - VR scenes: VRSpace, GameShelve (game selection), VRMenuPanel
- `game-client/` - SvelteKit smartphone controller app (see game-client/AGENTS.md)
- `mods-unpacked/KumaGee-VRCore/` - Mini-games and shared player system
  - `player/` - FPSPlayer, PlayerSpawner, ClientController abstraction (phone/gamepad/AI)
- `addons/` - Godot plugins: mod_loader (autoloaded), godot-xr-tools, webrtc, qr_code, barcode, proton_scatter, godot-css-theme
- `assets/` - Raw art assets (characters, textures, sounds, particles)
- `build/` - Export output (`build/web/` served by HttpServer on port 8484)
- `shader/` - Custom GLSL shaders
- `theme/` - Godot theme resources
- `gdd/` - Design docs and task files

### Autoloads (project.godot)

| Singleton | Script | Role |
|---|---|---|
| ModLoaderStore | `addons/mod_loader/mod_loader_store.gd` | Mod list state |
| ModLoader | `addons/mod_loader/mod_loader.gd` | Scans and loads mods from `mods-unpacked/` |
| HttpServer | `main/utils/http_server.gd` | Serves `build/web` on port 8484 |
| LobbyServer | `main/utils/lobby_server.gd` | WebSocket signaling server on port 14412 |
| PlayerManager | `main/utils/player_manager.gd` | Manages all connected clients (WebRTC + gamepads) |
| StatsManager | `main/utils/stats_manager.gd` | Per-player deaths, damage, score tracking |
| BGMManager | `main/utils/bgm_manager.gd` | Background music with volume control |
| GameSettings | `main/utils/game_settings.gd` | Game configuration (AI count, etc.) |
| AudioManager | `main/utils/audio_manager.gd` | SFX bus management |
| Staging | `addons/godot-xr-tools/...` | Scene lifecycle helper |
| XRToolsUserSettings | godot-xr-tools | XR user settings |
| XRToolsRumbleManager | godot-xr-tools | Controller rumble |

## Mini-Game Structure

**Registration:** A mini-game is a `.tres` file of class `GameResource` (`main/game_resource.gd`):

```gdscript
class_name GameResource extends Resource
@export var name: String
@export_multiline var description: String
@export var scene: PackedScene        # game scene to load
@export var icon: PackedScene         # 3D icon for VR shelf
@export var min_recommended_players := 2
@export var max_recommended_players := -1
@export var vr_preview: Texture2D
@export var desktop_preview: Texture2D
```

`GameLoader.list_games()` (`main/utils/game_loader.gd`) recursively scans every enabled mod's folder in `mods-unpacked/` for any `.tres` that loads as `GameResource`. No explicit registration needed — just drop a `.tres` file anywhere inside a mod folder.

**Game lifecycle:** The game scene root must extend `XRToolsSceneBase` (from godot-xr-tools), which provides:
- `xr_player` — the VR player node, exposes `gameover(message)` to show results
- `load_scene(path)` — scene transition to next game or menu
- Standard prepare → start → gameover flow

**Player abstraction (`mods-unpacked/.../player/`):**
- `ClientController` — abstract base with signals `primary_action_pressed`, `secondary_action_pressed`, and method `get_move() -> Vector2`
- Three implementations: `GameClient` (WebRTC phone), `GamepadController` (physical gamepad), `AIClientController` (AI bot)
- `FPSPlayer` holds a `game_client: ClientController` and calls `get_move()` each physics frame. Game code never knows which controller type it's talking to.

## Build & Dev Commands

### SvelteKit Controller
```bash
cd game-client
bun run dev      # Dev server on port 8080
bun run build    # Builds to build/, then copies to ../build/web
```

## Communication Flow

1. **Phone scans QR code** (served by Godot's QR code addon) — URL includes `?ip=<server_ip>`
2. **SvelteKit app loads** from Godot's HttpServer (port 8484) and reads the `?ip=` param
3. **WebSocket connection** to LobbyServer (port 14412) — player signaling/handshake
4. **WebRTC data channel** (pre-negotiated, id=1) — all real-time input data flows here
5. **Godot receives inputs** via semicolon-delimited string protocol: `"move;x;y"` (joystick), `"name;1/0"` (buttons)

## Guidelines

- Don't create any documentation markdown files unless explicitly requested
- Don't add comments unless it's really not clear why it's been done that way
