import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';
import {
  selectAndStartGame,
  vrPlayerReady,
  markAllMobilePlayersReady,
  registerGamepadPlayer,
  waitForNodeType,
  waitForJoinedPlayers,
  restorePromptForContinue,
} from './helpers/vr-player';

const PLAYER_MANAGER_PATH = '/root/PlayerManager';
const STAGING_PATH = '/root/Staging';
const MENU_WORLD_PATH = '/root/Staging/Scene/MenuWorld';

const PHONE_UUID = 'e2e-test-vr-phone-0000-0000-000000000030';
const GAMEPAD_UUID = 'e2e-test-vr-gamepad-0000-0000-000000000032';

const CASTLE_DEFENSE_PATH =
  'res://mods-unpacked/KumaGee-VRCore/castle-defense/castle_defense.tres';
const DRAW_AND_GUESS_PATH =
  'res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tres';

/**
 * Navigate back to the MenuWorld after a game scene test.
 */
async function returnToMenuWorld(mcp: import('./helpers/mcp-bridge').MCPBridge): Promise<void> {
  const scenes = await mcp.listNodesByType('XRToolsSceneBase') as string[];
  const gameScene = scenes.find(p => p.startsWith('/root/Staging/Scene/') && !p.includes('MenuWorld'));
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

test.afterEach(async ({ mcp }) => {
  // Return to MenuWorld first (frees resources of the loaded game scene)
  await returnToMenuWorld(mcp);
  await new Promise((r) => setTimeout(r, 500));

  // Restore prompt_for_continue to default
  await restorePromptForContinue(mcp);

  // Remove all players
  await mcp.callMethod(PLAYER_MANAGER_PATH, 'remove_all_players', []);
  await new Promise((r) => setTimeout(r, 500));
});

test.describe('VR player game lifecycle', () => {
  test('Draw & Guess: VR selects & starts game, then mobile + VR ready starts game', async ({
    page,
    mcp,
  }) => {
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);

    await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);

    const gamePath = await waitForNodeType(mcp, 'BaseGame', 25_000);
    await waitForJoinedPlayers(mcp, gamePath, 10_000);

    await markAllMobilePlayersReady(mcp);
    await page.waitForTimeout(500);

    await vrPlayerReady(mcp, gamePath);
    await page.waitForTimeout(2000);

    const props = await mcp.getProperties(gamePath);
    expect(props.is_game_phase).toBe(true);
  });

  test('Castle Defense: VR selects & starts game, then mobile + VR ready up', async ({
    page,
    mcp,
  }) => {
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);

    await registerGamepadPlayer(mcp, GAMEPAD_UUID);
    await page.waitForTimeout(1000);

    await selectAndStartGame(mcp, CASTLE_DEFENSE_PATH);

    const castlePath = await waitForNodeType(mcp, 'CastleDefense', 25_000);
    await waitForJoinedPlayers(mcp, castlePath, 10_000);

    await markAllMobilePlayersReady(mcp);
    await page.waitForTimeout(500);

    await vrPlayerReady(mcp, castlePath);
    await page.waitForTimeout(2000);

    const playTimeProps = await mcp.getProperties(`${castlePath}/PlayTime`);
    expect(playTimeProps.time_left).toBeGreaterThan(0);
  });
});
