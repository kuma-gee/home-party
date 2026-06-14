/**
 * Shared cleanup utilities for E2E tests.
 *
 * Functions for returning to the MenuWorld, restoring game state,
 * and removing players after a test completes.
 */
import type { MCPBridge } from './mcp-bridge';
import { STAGING_PATH, MENU_WORLD_PATH, PLAYER_MANAGER_PATH } from './constants';

/**
 * Navigate back to the MenuWorld after a game scene test.
 * Finds the active game scene and emits `request_exit_to_main_menu`,
 * then waits for MenuWorld to reappear in the scene tree.
 */
export async function returnToMenuWorld(mcp: MCPBridge): Promise<void> {
  const scenes = (await mcp.listNodesByType('XRToolsSceneBase')) as string[];
  const gameScene = scenes.find(
    (p) => p.startsWith('/root/Staging/Scene/') && !p.includes('MenuWorld'),
  );
  if (!gameScene) return;

  // Disable prompt_for_continue so loading screen doesn't block
  await mcp.callMethod(STAGING_PATH, 'set', ['prompt_for_continue', false]);

  // Request return to main menu via the game scene's signal
  await mcp.callMethod(gameScene, 'emit_signal', ['request_exit_to_main_menu']);

  // Wait for MenuWorld to reappear
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    const node = await mcp.getNode(MENU_WORLD_PATH);
    if (node?.type) break;
    await new Promise((r) => setTimeout(r, 500));
  }
}

/**
 * Standard cleanup after a mini-game scene test:
 * 1. Return to MenuWorld (frees loaded game resources)
 * 2. Restore prompt_for_continue to default
 * 3. Remove all connected players
 */
export async function cleanupAfterGameScene(mcp: MCPBridge): Promise<void> {
  await returnToMenuWorld(mcp);
  await new Promise((r) => setTimeout(r, 500));

  // Restore prompt_for_continue to default
  await mcp.callMethod(STAGING_PATH, 'set', ['prompt_for_continue', true]);

  // Remove all players
  await mcp.callMethod(PLAYER_MANAGER_PATH, 'remove_all_players', []);
  await new Promise((r) => setTimeout(r, 500));
}

/**
 * Minimal cleanup after a non-game test:
 * Removes all connected players.
 */
export async function cleanupPlayers(mcp: MCPBridge): Promise<void> {
  await mcp.callMethod(PLAYER_MANAGER_PATH, 'remove_all_players', []);
  await new Promise((r) => setTimeout(r, 500));
}
