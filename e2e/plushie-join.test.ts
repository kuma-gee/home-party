import { test, expect } from './helpers/godot-fixture';
import { navigateToGame, connectMobilePlayer, connectPlayer } from './helpers/player';
import type { MCPBridge } from './helpers/mcp-bridge';

const PLAYER_UUID = 'e2e-test-plushie-0000-0000-000000000001';
const PLAYER_LIST_PATH =
  '/root/Staging/Scene/MenuWorld/CanvasLayer/Control/MarginContainer/PlayerList';

async function verifyPlushieIdentity(
  mcp: MCPBridge,
  plushiePath: string,
  uuid: string,
  index: number,
  tag: string,
) {
  const props = await mcp.getProperties(plushiePath);
  expect(props.player_uuid).toBe(uuid);
  expect(props.player_index).toBe(index);

  const tagProps = await mcp.getProperties(`${plushiePath}/PlayerTag`);
  expect(tagProps.text).toBe(tag);
}

test('mobile player connects → plushie appears with correct identity', async ({ page, mcp }) => {
  await navigateToGame(page, PLAYER_UUID);
  await page.waitForTimeout(2000);

  await connectMobilePlayer(page);

  const plushiePath = await mcp.findNode('Plushie', true, 'RigidBody3D');
  expect(plushiePath).toBeTruthy();
  const plushieInfo = await mcp.getNode(plushiePath!);
  expect(plushieInfo.type).toBe('RigidBody3D');

  await verifyPlushieIdentity(mcp, plushiePath!, PLAYER_UUID, 0, 'P1');

  const playerCount = await mcp.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
  expect(playerCount.result).toBe(1);
});

test('disconnecting deactivates the player in Godot', async ({ page, mcp }) => {
  const uuid = 'e2e-test-plushie-0000-0000-000000000002';

  await connectPlayer(page, uuid);

  let playerCount = await mcp.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
  expect(playerCount.result).toBe(1);

  await page.locator('.disconnect-icon').click();
  await expect(page.locator('h2')).toHaveText('Connect to Game Server', { timeout: 15_000 });
  await page.waitForTimeout(2000);

  playerCount = await mcp.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
  expect(playerCount.result).toBe(0);
});
