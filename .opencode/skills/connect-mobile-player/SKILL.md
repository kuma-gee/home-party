---
name: connect-mobile-player
description: How to connect as a mobile player through the game-client phone controller app.
---

# Connect Mobile Player

The game-client is a SvelteKit SPA served by Godot's built-in HttpServer. The phone acts as a pure controller — all visuals stay on the shared screen.

## Quick Reference

| What | Where |
|---|---|
| Controller URL | `http://localhost:8484/` |
| WebSocket signaling | `ws://localhost:14412` |

## How to connect

1. **Open website** — `http://localhost:8484/`.
2. **Press connect button**
3. **Input layout** — server sends the active layout (`"joystick"`, `"buttons"`, or `"guess"`).

## Input Wire Protocol

UTF-8 semicolon-delimited strings over the data channel:

| Type | Format | Example |
|---|---|---|
| Button press | `name;1` | `action;1` |
| Button release | `name;0` | `action;0` |
| Joystick | `name;x;y` | `move;-0.73;0.41` |
| Text | `text` | `word;hello` |

Named inputs: `move` (joystick), `action` (A), `secondary` (B).

## Reconnection

The phone retries up to 5 times with linear backoff (1s, 2s, …, 5s). The stored UUID lets the server pick up the same `GameClient` node on reconnect. After exhausting retries the phone shows the connection form again.

## On the Godot side

`PlayerManager` listens to `LobbyServer` signals (`player_connected`, `player_disconnected`, etc.) and creates/reuses `GameClient` nodes (extends `ClientController`). Each `GameClient._process()` polls the data channel, parses semicolon-delimited strings, and emits `input_received` and `moved` signals that mini-game logic connects to.

## Testing multiple players with Playwright

When connecting multiple players via Playwright, **always use separate browser sessions** (`-s` flag). Tabs in the same session share WebRTC/WebSocket state and get stuck on "Connecting...".

```bash
# Player 1 — default session
playwright-cli open --browser=firefox http://localhost:8484/
playwright-cli click e9

# Players 2, 3, … — separate named sessions
playwright-cli -s=player2 open --browser=firefox http://localhost:8484/
playwright-cli -s=player2 click e9

playwright-cli -s=player3 open --browser=firefox http://localhost:8484/
playwright-cli -s=player3 click e9
```

After each connects, verify they appear under `/root/PlayerManager`:

```bash
godot-debug_get_node_snapshot /root/PlayerManager
```

Clean up at the end:

```bash
playwright-cli close && playwright-cli -s=player2 close
```