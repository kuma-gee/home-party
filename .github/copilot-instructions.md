# Copilot Instructions for `home-party`

## Build, test, and lint

### Web controller (`game-client/`)
- Install deps: `cd game-client && npm install`
- Dev server: `cd game-client && npm run dev`
- Production build: `cd game-client && npm run build`
  - Builds the Svelte app and copies the output into `../build/web/`, which is what the Godot host serves to phones.
- Alternate no-telemetry scripts from the template: `cd game-client && npm run dev-nolog`, `cd game-client && npm run build-nolog`

### Godot host
- The project is a Godot 4.6 project rooted at the repository root (`project.godot`).
- Web export is configured in `export_presets.cfg` with output `build/web/index.html`.
- Existing project guidance uses the Godot editor export flow for the host/web export.

### Tests / lint / type checks
- No automated test suite is currently defined in the repository.
- No lint script is defined in `package.json`.
- There is no single-test command because there are no repo tests yet.
- For Svelte/TypeScript validation in the web client, `svelte-check` is available from `game-client/` via `npx svelte-check`.

## High-level architecture

This repository is two connected apps:

1. **Godot VR host/server**
   - Main scene is `main/game.tscn`, which instantiates XR Tools staging and loads the menu world.
   - Core long-lived services are autoloads from `project.godot`:
     - `LobbyServer` (`main/utils/lobby_server.gd`) — WebSocket signaling server on port `14412`
     - `PlayerManager` (`main/utils/player_manager.gd`) — creates one `GameClient` node per connected phone and snapshots `playing_clients` when a game starts
     - `HttpServer` (`main/utils/http_server.gd`) — serves `build/web/` on port `8484`
     - `ModLoader` — loads unpacked mods at startup
   - `main/menu_world.gd` listens for a selected `GameResource` and loads that scene into the XR staging flow.

2. **Phone controller web app**
   - Lives under `game-client/` and is a SvelteKit app.
   - The active controller UI is in `game-client/src/routes/+page.svelte` plus networking/state code in `game-client/src/lib/`.
   - Phones load the static app from the Godot host (`HttpServer`), then connect back to the same host over WebSocket (`14412`) for signaling and WebRTC for live inputs.

### Runtime flow
- `main/main_menu.gd` uses `GameLoader` (`main/utils/game_loader.gd`) to recursively scan enabled mods under `mods-unpacked/` for `.tres` resources whose script is `GameResource`.
- The selected `GameResource.scene` is loaded by the XR menu/staging scene.
- When a phone connects:
  - `LobbyServer` assigns an ID and sends the current input layout.
  - The web client replies with `peer_id`, a persistent `client_id` from `localStorage`, and the player name.
  - `PlayerManager` creates a `GameClient` node for that peer.
  - The web client then establishes a negotiated WebRTC data channel named `inputs` with id `1`.
- When a game starts, `PlayerManager.start_game()` snapshots the currently connected `GameClient` nodes into `playing_clients`. Mini-games read from that list.

### Built-in game/mod structure
- Active bundled mods live in `mods-unpacked/KumaGee-VRCore/`.
- Each playable mini-game is discovered from a `.tres` `GameResource` that points at:
  - a playable `.tscn`
  - an icon scene
  - metadata such as name, description, and tags
- Existing mini-games often extend `XRToolsSceneBase` and do startup work in `scene_loaded(user_data = null)`.

## Key conventions

- **Do not modify `addons/` casually.** It contains third-party plugins (XR Tools, mod loader, QR/barcode helpers, CSS theme, etc.). Read it when needed, but treat it as external code.
- **Use the autoloads instead of parallel implementations.** Networking and player lifecycle already live in `LobbyServer`, `PlayerManager`, and `HttpServer`.
- **Mini-games are mod resources, not hardcoded menu entries.**
  - Add or change games by updating mod content under `mods-unpacked/`
  - Keep the `.tres` `GameResource` accurate, since `GameLoader` discovers games by loading resources recursively
- **Phone UI layout is server-driven.**
  - Godot switches the controller UI with `LobbyServer.send_layout("joystick")` or `LobbyServer.send_layout("buttons")`
  - The web client store only expects those two layout strings
- **Input protocol is string-based over the WebRTC data channel.**
  - Boolean/button input: `"name;1"` or `"name;0"`
  - Vector input: `"name;x;y"`
  - Current built-in gameplay uses names like `"move"`, `"action"`, and `"secondary"`
- **Server-side gameplay scripts usually consume input in two ways:**
  - subscribe to `game_client.input_received` for button-style actions
  - poll `game_client.get_move()` during `_physics_process()` for movement
- **The live web controller is not the Phaser template scaffolding.**
  - Real controller logic is in `game-client/src/routes` and `game-client/src/lib`
  - `game-client/src/game/*` and `game-client/src/PhaserGame.svelte` are template leftovers and are not the main controller flow
- **SvelteKit SSR is intentionally disabled** in `game-client/src/routes/+layout.js`; keep browser-only logic on the client side.
- **Web-client changes are not automatically visible to the Godot host until rebuilt.**
  - `npm run build` is what syncs the controller app into `build/web/`
- **UI/player lobby data is keyed by persistent client UUID, not only transient peer ID.**
  - `LobbyServer` tracks both `peer_id` and `client_id`
  - UI such as `main/ui/player_list.gd` updates players by `client_id`