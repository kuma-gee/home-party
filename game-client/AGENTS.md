# Game Client — Smartphone Controller

**Purpose:** Pure input controller for the Home Party VR game.
No game state, scores, graphics, or info is displayed here —
all visual feedback is shown on the shared desktop view.
The controller is strictly a gamepad replacement.

Everything is in a single route and the layout of it can be
switched by the game to match the needed inputs.

## Connection Flow

```
+page.svelte → store.connect(ip)
                   ↓
WebSocket → ws://ip:14412  (handshake + signaling)
                   ↓
WebRTC data channel (pre-negotiated, id=1)  ← all inputs sent here
```

1. **WebSocket** connects, exchanges ID
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
| `src/lib/store.ts` | Central `connectionStore` — wraps WebSocket client, exposes derived stores (`isConnected`, `peerId`, `inputLayout`, `webrtcState`, `reconnecting`) |
| `src/lib/websocket.ts` | WebSocket client — connects to LobbyServer, handles signaling messages (Id, Description, ICE Candidate, InputLayout) |
| `src/lib/webrtc.ts` | WebRTC client — creates peer connection + data channel, handles offer/answer, sends inputs |
| `src/lib/layouts/JoystickLayout.svelte` | Full controller UI — left joystick, right A/B buttons |
| `src/lib/VirtualJoystick.svelte` | Dual-mode joystick component — `"joystick"` mode (analog stick) or `"buttons"` mode (d-pad arrows) |

## Server-Controlled Layout

Godot can switch the controller layout mid-session by sending `msg type 3` with `layout: "joystick"` or `"buttons"`. The `inputLayout` store drives which `VirtualJoystick` mode is active.

## Player Identity

- **UUID:** generated on first connect via `crypto.randomUUID()`, persisted in `localStorage("clientId")` — reused on reconnect so `PlayerManager` recognizes returning players

## Building

Run this command to create a clean build for the game

```
bun run build
```