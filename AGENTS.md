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

## Mini-Game Structure

**Registration:** A mini-game is a `.tres` file of class `GameResource` (`main/game_resource.gd`):

`GameLoader.list_games()` (`main/utils/game_loader.gd`) recursively scans every enabled mod's folder in `mods-unpacked/` for any `.tres` that loads as `GameResource`. No explicit registration needed — just drop a `.tres` file anywhere inside a mod folder.

**Game lifecycle:** The game scene root must extend `XRToolsSceneBase` (from godot-xr-tools), which provides:
- `xr_player` — the VR player node, exposes `gameover(message)` to show results
- `load_scene(path)` — scene transition to next game or menu
- Standard prepare → start → gameover flow

**Player abstraction (`mods-unpacked/.../player/`):**
- `ClientController` — abstract base with signals `primary_action_pressed`, `secondary_action_pressed`, and method `get_move() -> Vector2`
- Three implementations: `GameClient` (WebRTC phone), `GamepadController` (physical gamepad), `AIClientController` (AI bot)
- `FPSPlayer` holds a `game_client: ClientController` and calls `get_move()` each physics frame. Game code never knows which controller type it's talking to.

## Communication Flow

1. **Phone scans QR code** (served by Godot's QR code addon) — URL includes `?ip=<server_ip>`
2. **SvelteKit app loads** from Godot's HttpServer (port 8484) and reads the `?ip=` param
3. **WebSocket connection** to LobbyServer (port 14412) — player signaling/handshake
4. **WebRTC data channel** (pre-negotiated, id=1) — all real-time input data flows here
5. **Godot receives inputs** via semicolon-delimited string protocol: `"move;x;y"` (joystick), `"name;1/0"` (buttons)

## MUST FOLLOW

- Don't create any documentation markdown files unless explicitly requested
- Don't add comments unless it's really not clear why it's been done that way
- Prefer creating nodes in the scenes directly if it's not dynamic
- Create nodes in the scenes and not via code
- Use `@export` for nodes deeper than one levele inside the tree
- Use the `theme.css` resource for all root control nodes