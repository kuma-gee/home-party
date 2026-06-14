import { MCPBridge } from './mcp-bridge';

const GAME_SHELVE_PATH = '/root/Staging/Scene/MenuWorld/GameShelve';
const PLAYER_MANAGER_PATH = '/root/PlayerManager';
const STAGING_PATH = '/root/Staging';

/**
 * Select a game on the shelf (equivalent to VR player dropping a game box
 * into the snap zone).
 */
export async function selectGame(mcp: MCPBridge, resourcePath: string): Promise<void> {
  await mcp.callMethod(GAME_SHELVE_PATH, 'select_game_with_path', [resourcePath]);
  await new Promise((r) => setTimeout(r, 500));
}

/**
 * Start the currently selected game (equivalent to VR player pressing the
 * TV remote button). Calls start_selected_game() directly via MCP bridge.
 *
 * Disables the VR "Hold to Continue" prompt on the loading screen so the
 * game scene loads immediately without requiring VR interaction.
 */
export async function startSelectedGame(mcp: MCPBridge): Promise<void> {
  // Disable the VR "Hold to Continue" prompt so scene loads immediately
  await mcp.callMethod(STAGING_PATH, 'set', ['prompt_for_continue', false]);
  await new Promise((r) => setTimeout(r, 200));

  await mcp.callMethod(GAME_SHELVE_PATH, 'start_selected_game', []);
  await new Promise((r) => setTimeout(r, 1500));
}

/**
 * Convenience: select a game, start it (with loading screen bypassed).
 */
export async function selectAndStartGame(mcp: MCPBridge, resourcePath: string): Promise<void> {
  await selectGame(mcp, resourcePath);
  await startSelectedGame(mcp);
}

/**
 * Restore prompt_for_continue to its default value (true) after a test.
 */
export async function restorePromptForContinue(mcp: MCPBridge): Promise<void> {
  await mcp.callMethod(STAGING_PATH, 'set', ['prompt_for_continue', true]);
}

/**
 * VR player signals ready in the current mini-game.
 * Auto-detects the game type and calls the appropriate method.
 * If no game path is provided, it tries to find one.
 */
export async function vrPlayerReady(
  mcp: MCPBridge,
  gamePath?: string,
): Promise<void> {
  if (!gamePath) {
    const castleDefenseNodes = (await mcp.listNodesByType('CastleDefense')) as string[];
    const castlePath = castleDefenseNodes.find((p) =>
      p.startsWith('/root/Staging/Scene/'),
    );
    if (castlePath) {
      gamePath = castlePath;
    } else {
      const baseGameNodes = (await mcp.listNodesByType('BaseGame')) as string[];
      const basePath = baseGameNodes.find((p) =>
        p.startsWith('/root/Staging/Scene/') && !p.includes('MenuWorld'),
      );
      if (basePath) {
        gamePath = basePath;
      }
    }
  }

  if (!gamePath) {
    throw new Error('No active game scene found for VR player ready');
  }

  // CastelDefense uses _on_vr_ready, BaseGame uses check_all_ready(true)
  if ((await mcp.listNodesByType('CastleDefense')).includes(gamePath)) {
    await mcp.callMethod(gamePath, 'vr_player_ready', []);
  } else {
    await mcp.callMethod(gamePath, 'check_all_ready', [true]);
  }
  await new Promise((r) => setTimeout(r, 500));
}

/**
 * Wait until a node type appears in the scene tree, with a timeout.
 * Returns the path of the first matching node under /root/Staging/Scene/.
 */
export async function waitForNodeType(
  mcp: MCPBridge,
  typeName: string,
  timeoutMs = 20_000,
): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const nodes = (await mcp.listNodesByType(typeName)) as string[];
    const match = nodes.find((p) => p.startsWith('/root/Staging/Scene/'));
    if (match) return match;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`Node type "${typeName}" did not appear within ${timeoutMs}ms`);
}

/**
 * Wait until at least `count` JoinedPlayers appear under the given scene path.
 */
export async function waitForJoinedPlayers(
  mcp: MCPBridge,
  scenePath: string,
  timeoutMs = 10_000,
  count = 1,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const players = (await mcp.listNodesByType('JoinedPlayer')) as string[];
    const inScene = players.filter((p) => p.startsWith(scenePath));
    if (inScene.length >= count) return;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`Expected ${count} JoinedPlayers under ${scenePath} but got fewer within ${timeoutMs}ms`);
}

/**
 * Mark all connected mobile players as ready by calling set_ready() on each
 * JoinedPlayer node that has a uuid.
 */
export async function markAllMobilePlayersReady(mcp: MCPBridge): Promise<void> {
  const players = (await mcp.listNodesByType('JoinedPlayer')) as string[];
  for (const path of players) {
    const props = await mcp.getProperties(path);
    if (props.uuid) {
      await mcp.callMethod(path, 'set_ready', []);
    }
  }
}

/**
 * Register a fake gamepad player for testing.
 */
export async function registerGamepadPlayer(mcp: MCPBridge, uuid: string): Promise<void> {
  await mcp.callMethod(PLAYER_MANAGER_PATH, 'register_fake_gamepad', [uuid]);
  await new Promise((r) => setTimeout(r, 1000));
}
