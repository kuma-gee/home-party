import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';
import { cleanupPlayers } from './helpers/cleanup';
import type { MCPBridge } from './helpers/mcp-bridge';

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

test.afterEach(async ({ mcp }) => {
  await cleanupPlayers(mcp);
});

test('two players connect with different plushie models, then disconnect and disappear', async ({ page, mcp }) => {
  const uuid1 = 'e2e-test-plushie-0000-0000-000000000004';
  const uuid2 = 'e2e-test-plushie-0000-0000-000000000005';

  await connectPlayer(page, uuid1);

  const browser = page.context().browser()!;
  const context2 = await browser.newContext();
  const page2 = await context2.newPage();
  try {
    await connectPlayer(page2, uuid2);
    await page.waitForTimeout(1000);

    const allBodies = (await mcp.listNodesByType('RigidBody3D')) as string[];
    const plushiePaths = allBodies.filter((p) => p.includes('Plushie'));
    expect(plushiePaths).toHaveLength(2);

    const props0 = await mcp.getProperties(plushiePaths[0]);
    const p1Path = props0.player_uuid === uuid1 ? plushiePaths[0] : plushiePaths[1];
    const p2Path = props0.player_uuid === uuid2 ? plushiePaths[0] : plushiePaths[1];

    await verifyPlushieIdentity(mcp, p1Path, uuid1, 0, 'P1');
    await verifyPlushieIdentity(mcp, p2Path, uuid2, 1, 'P2');

    const model1 = (await mcp.callMethod(p1Path, 'get_visible_model', [])).result as string;
    const model2 = (await mcp.callMethod(p2Path, 'get_visible_model', [])).result as string;

    expect(model1).toBeTruthy();
    expect(model2).toBeTruthy();
    expect(model1).toMatch(/^animal-/);
    expect(model2).toMatch(/^animal-/);
    expect(model1).not.toBe(model2);

    await page2.locator('.disconnect-icon').click();
    await expect(page2.locator('h2')).toHaveText('Connect to Game Server', { timeout: 15_000 });
    await page.waitForTimeout(2000);

    let playerCount = await mcp.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
    expect(playerCount.result).toBe(1);

    await page.locator('.disconnect-icon').click();
    await expect(page.locator('h2')).toHaveText('Connect to Game Server', { timeout: 15_000 });
    await page.waitForTimeout(2000);

    playerCount = await mcp.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
    expect(playerCount.result).toBe(0);
  } finally {
    await context2.close();
  }
});
