# Game Client — Smartphone Controller

**Purpose:** Pure input controller for the Home Party VR game.
No game state, scores, graphics, or info is displayed here — all visual feedback is shown on the shared desktop view.
The controller is strictly a gamepad replacement.

## Tech Stack

- **SvelteKit 2** with **Svelte 5** runes (`$state`, `$effect`, `$props`)
- **TypeScript** throughout
- **Vite 6** with `@sveltejs/adapter-static` — builds to `build/`, then copied to `../build/web`
- **Zero runtime dependencies** — everything in devDependencies only
- **SSR disabled** — pure client-side SPA

## Routing

Single route `/` — no sub-routes. The entire app is one page.

- `+page.svelte` — main controller UI. On mount, reads `?ip=` from query params and auto-connects. Locks screen to landscape.
- `+layout.svelte` — sets page title and global body styles (black background).

## Connection Flow

```
+page.svelte → store.connect(ip, name)
                   ↓
WebSocket → ws://ip:14412  (handshake + signaling)
                   ↓
WebRTC data channel (pre-negotiated, id=1)  ← all inputs sent here
```

1. **WebSocket** connects, exchanges ID + player info
2. **WebRTC offer/answer** negotiates a data channel (fixed id=1, negotiated=true)
3. **Data channel opens** — inputs begin flowing
4. **Reconnect** — up to 5 attempts with backoff; player UUID in `localStorage("clientId")` lets the server recognize returning players

## Input Wire Protocol

All inputs flow over the **WebRTC data channel** as UTF-8 semicolon-delimited strings:

| Type | Format | Example |
|---|---|---|
| Button press | `"name;1"` | `"action;1"` |
| Button release | `"name;0"` | `"action;0"` |
| Joystick move | `"name;x;y"` | `"move;-0.73;0.41"` |

**Named inputs:** `move` (joystick), `action` (primary/A button), `secondary` (secondary/B button)

## Key Files

| File | Role |
|---|---|
| `src/lib/store.ts` | Central `connectionStore` — wraps WebSocket client, exposes derived stores (`isConnected`, `peerId`, `inputLayout`, `webrtcState`, `dataChannelMessage`, `reconnecting`) |
| `src/lib/websocket.ts` | WebSocket client — connects to LobbyServer, handles signaling messages (Id, Description, ICE Candidate, InputLayout) |
| `src/lib/webrtc.ts` | WebRTC client — creates peer connection + data channel, handles offer/answer, sends inputs |
| `src/lib/layouts/JoystickLayout.svelte` | Full controller UI — left joystick, center message overlay, right A/B buttons |
| `src/lib/VirtualJoystick.svelte` | Dual-mode joystick component — `"joystick"` mode (analog stick) or `"buttons"` mode (d-pad arrows) |
| `src/lib/icons.ts` | 11 Unicode icons mapped by player number for display |

## Server-Controlled Layout

Godot can switch the controller layout mid-session by sending `msg type 3` with `layout: "joystick"` or `"buttons"`. The `inputLayout` store drives which `VirtualJoystick` mode is active.

## Player Identity

- **Name:** saved to `localStorage("playerName")`
- **UUID:** generated on first connect via `crypto.randomUUID()`, persisted in `localStorage("clientId")` — reused on reconnect so `PlayerManager` recognizes returning players
- **Icon:** assigned server-side by player number (0–N, modulo 11), sent back with the Id message
