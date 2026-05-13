# AGENTS.md

## Project Structure

**Dual-runtime VR game:** Godot 4.6 VR game + SvelteKit smartphone controller (WebRTC connected)

- `main/` - Core VR game, menu system, autoloads (HttpServer, LobbyServer, PlayerManager, etc.)
- `game-client/` - SvelteKit TypeScript app, builds to `build/web`, copied by Godot's HttpServer
- `mods-unpacked/KumaGee-VRCore/` - Mod system with game modes (castle-defense, warehouse, pirate, whack-a-mole)
- `addons/` - Godot plugins: mod_loader (autoloaded), godot-xr-tools, webrtc, barcode, qr_code, proton_scatter

**Main scene:** `run/main_scene="uid://dfokhnxe3wv3r"` (project.godot:18)

## Build & Dev Commands

### Godot VR Game
- Run directly in Godot editor or export via `export_presets.cfg` → `build/web/index.html`
- Physics: Jolt Physics engine (project.godot:98)
- OpenXR enabled with hand tracking

### SvelteKit Controller
```bash
cd game-client
bun run dev      # Dev server on port 8080 (vite/config.dev.mjs)
bun run build    # Builds to game-client/build, copies to ../build/web
```

**Critical:** SvelteKit build uses `adapter-static` with `fallback: 'index.html'` for SPA mode. Build step copies output to `../build/web` where Godot's HttpServer (port 8484) serves it.

## Architecture Notes

**Communication flow:**
1. Godot's `HttpServer` autoload serves static files from `build/web` on port 8484
2. `LobbyServer` autoload runs WebSocket server on port 14412 for player signaling
3. Game clients connect via WebRTC for input (joystick or buttons layout)

**Mod system:** Uses `ModLoader` and `ModLoaderStore` autoloads. Mods live in `mods-unpacked/<ModName>/mod_main.gd`

**Layer setup:** Custom 3D physics layers (project.godot:77-94) - PlayerHurtBox (6), EnemyHurtBox (7), Held Objects (17), Player Hands (18), etc.

## Guidelines

- Don't create any documentation markdown files unless explicitly requested
- Don't add comments unless it's really not clear why it's been done that way

## Testing

No CI workflows detected. Test in Godot editor for VR features, verify WebRTC signaling by running game + opening `http://localhost:8484` in smartphone browser.
