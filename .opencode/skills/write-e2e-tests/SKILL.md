---
name: write-e2e-tests
description: Write and structure end-to-end tests for mini-games using Playwright and the Godot MCP bridge to verify complete workflows instead of isolated units. Use when writing E2E tests
---

# Write E2E Tests

End-to-end (e2e) tests verify complete **workflows** — from game load to phase transitions to scoring — rather than isolated functions. They catch integration bugs that unit tests miss: signal wiring, state machine gaps, data flow errors between subsystems.

Tests are TypeScript files run by Playwright. They use two tools:

| Tool | Role |
|---|---|
| **MCPBridge helper** (`e2e/helpers/mcp-bridge.ts`) | TCP client to Godot's MCP bridge — inspect scene tree, call methods, check properties, take snapshots |
| **Playwright** (`@playwright/test`) | Open browsers that connect as mobile phone controllers, send button presses / text input, assert on browser state |

## Philosophy

| Principle | Meaning |
|---|---|
| **Test workflows, not features** | A single e2e test might cover launching, player joining via Playwright, game phase transitions, round completion, and scoring. Avoid tiny tests per function. |
| **Interact through MCP** | Call methods on game objects via `mcp.callMethod()` to drive state. Use Playwright only for mobile phone UI interactions. |
| **Share test code** | Put reusable code in `e2e/helpers/` — don't duplicate across test files and keep it small. Not a new file for every helper. |
| **Fewer, heavier tests** | Don't chase 100% coverage. Test the critical paths: the main flow (happy path), one major edge case, and one failure mode per mini-game. |
| **No VR interaction** | Don't test picking up objects or throwing. Test what the object does (e.g. "can the pen draw a line?") by calling its methods via MCP. |
| **Add MCP tools sparingly** | If the MCP bridge doesn't have the capability you need, create a new MCP command using the `add-mcp-function` skill. Keep tools **universally usable**, not test-specific. |

## Directory Structure

```
e2e/
  playwright.config.ts            # Playwright configuration
  global-setup.ts                 # Launches Godot with --mcp-bridge before all tests
  global-teardown.ts              # Kills Godot after all tests
  helpers/
		helpers.ts                 		# Reusable test helpers (connectPlayer, selectAndStartGame, etc.)
  test_<game_name>.test.ts        # One test file per mini-game (workflow tests)
```

## Writing Tests

### 1. Basic structure

```typescript
// e2e/test_hide_and_seek.test.ts
import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';
import {
  selectAndStartGame,
  vrPlayerReady,
  waitForNodeType,
  waitForJoinedPlayers,
} from './helpers/vr-player';
import { cleanupAfterGameScene } from './helpers/cleanup';
import { MY_GAME_PATH } from './helpers/constants';
import type { MCPBridge } from './helpers/mcp-bridge';

const PLAYER_UUID = 'e2e-test-0001-0000-000000000001';

test.setTimeout(120_000);

test.describe('My Game', () => {
  test.afterEach(async ({ mcp }) => {
    await cleanupAfterGameScene(mcp);
  });

  test('full game flow with 1 mobile player', async ({ page, mcp }) => {
    // ── Phase 1: Connection (Prepare Phase) ──
    await connectPlayer(page, PLAYER_UUID);
    await page.waitForTimeout(1000);

    // VR player selects and starts the game
    await selectAndStartGame(mcp, MY_GAME_PATH);

    // Wait for the game scene to load
    const gamePath = await waitForNodeType(mcp, 'BaseGame', 25_000);
    await waitForJoinedPlayers(mcp, gamePath, 10_000, 1);

    // Verify prepare phase UI is visible
    const prepareUI = await mcp.getProperties(`${gamePath}/CanvasLayer/Control/PrepareUI`);
    expect(prepareUI.visible).toBe(true);

    // ── Phase 2: Start Game ──
    // VR player signals ready
    await vrPlayerReady(mcp, gamePath);

    // Verify transition to game phase
    const gameProps = await mcp.getProperties(gamePath);
    expect(gameProps.is_game_phase).toBe(true);
    expect((await mcp.getProperties(`${gamePath}/CanvasLayer/Control/GameUI`)).visible).toBe(true);

    // ── Phase 3: Core Mechanic ──
    // Call game-specific methods directly (no VR interaction)
    const coreMechPath = `${gamePath}/CoreMechanic`;
    await mcp.callMethod(coreMechPath, 'do_action', []);
    // ... verify results via getProperties

    // ── Phase 4: End Game & Scoring ──
    // Complete the round / end the game via MCP
    const roundMgrPath = `${gamePath}/RoundManager`;
    await mcp.callMethod(roundMgrPath, 'end_round', []);
  });
});
```

### 2. Testing with multiple mobile players

When testing with multiple phone controllers, create **separate browser contexts** (each needs its own localStorage for client UUID):

```typescript
// In your test:
const browser = page.context().browser()!;
const context2 = await browser.newContext();
const page2 = await context2.newPage();

try {
  await connectPlayer(page, PLAYER_UUID_1);
  await connectPlayer(page2, PLAYER_UUID_2);
  // ...
} finally {
  await context2.close();
}
```

See `e2e/draw-and-guess.test.ts` and `e2e/plushie-lifecycle.test.ts` for full multi-player examples.

### 3. Testing without VR / XR

**Never** test the VR player's physical actions (grab, throw, teleport). Instead, drive the game logic via `mcp.callMethod()`:

| Instead of testing… | Call this via MCP… |
|---|---|
| "Player picks up the pen" | `mcp.callMethod(penPath, 'draw_line', [start, end])` |
| "Player throws the plushie" | `mcp.callMethod(plushiePath, 'apply_central_impulse', [[0, 10, 0]])` |
| "VR hand touches the button" | `mcp.callMethod(buttonPath, 'on_activate', [])` or `mcp.callMethod(buttonPath, 'emit_signal', ['pressed'])` |

This gives you reliable, deterministic tests that don't depend on physics simulation or VR hardware.

### 4. Inspecting game state via MCP

| What to check | MCPBridge method |
|---|---|
| Scene tree structure | `mcp.getSceneTree()`, `mcp.findNode(name)` |
| Node properties (position, visibility, score) | `mcp.getProperties(path)`, `mcp.getNodeSnapshot(path)` |
| Whether something changed | `mcp.takeSnapshot()` + `mcp.getDiff()` |
| Method return value | `mcp.callMethod(path, method, args)` (returns `{ result: ... }`) |
| Nodes of a specific type | `mcp.listNodesByType(typeName)` |
| Visual output | `mcp.takeScreenshot(filePath)` |
| Send keyboard input | `mcp.sendInput(keycode, opts)` |

**Waiting for state changes:** Use polling loops with timeouts:

```typescript
async function waitForPhase(mcp: MCPBridge, path: string, expected: number, timeoutMs = 10_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const props = await mcp.getProperties(path);
    if (props.phase === expected) return;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`Did not reach phase ${expected} within ${timeoutMs}ms`);
}
```

### 5. Adding `_debug_*` methods to game scripts

To make a game testable via MCP, add debug methods to its main script:

```gdscript
# Inside draw_and_guess.gd
func _debug_start_game() -> void:
	player_list.add_player("Tester")
	player_list.set_player_ready(0, true)
	check_all_ready(true)

func _debug_get_round_number() -> int:
	return %RoundManager.current_round

func _debug_end_round() -> void:
	%RoundManager.end_round()
```

Then call from tests:

```typescript
await mcp.callMethod(gamePath, '_debug_start_game', []);
const round = await mcp.callMethod(gamePath, '_debug_get_round_number', []);
```

**Naming convention:** Prefix test-support methods with `_debug_` so they're clearly not part of the public game API but can be relied upon by tests.

If many games need the same debug method, add it to `BaseGame` (`main/base_game.gd`).

## Adding MCP Functions for Tests

If a test workflow requires a capability the MCP bridge doesn't have:

1. **Add a new command to `main/utils/godot_mcp_bridge.gd`** — a new `match` arm + handler function
2. **Add a method to `e2e/helpers/mcp-bridge.ts`** — a TypeScript method on the `MCPBridge` class that calls `this.request()`
3. **Make it general** — the function should work for any game, not just one test
4. **Examples of useful additions:**
   - `listSignals(path)` — list all signals on a node
   - `getPropertyHistory(path, property)` — track changes to a property over time
   - `getChildrenByGroup(group)` — find nodes by group name
