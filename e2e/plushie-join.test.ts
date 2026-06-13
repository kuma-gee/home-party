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

test.afterEach(async ({ mcp }) => {
  await mcp.callMethod('/root/PlayerManager', 'remove_all_players', []);
  await new Promise((r) => setTimeout(r, 500));
});

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

test('two connected players get different animal models', async ({ page, mcp }) => {
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
    const props1 = await mcp.getProperties(plushiePaths[1]);
    const p1Path = props0.player_uuid === uuid1 ? plushiePaths[0] : plushiePaths[1];
    const p2Path = props0.player_uuid === uuid2 ? plushiePaths[0] : plushiePaths[1];

    await verifyPlushieIdentity(mcp, p1Path, uuid1, 0, 'P1');
    await verifyPlushieIdentity(mcp, p2Path, uuid2, 1, 'P2');

    const getVisibleModel = async (path: string): Promise<string | null> => {
      const models = await mcp.getNodeSnapshot(`${path}/Models`);
      for (const child of models.children ?? []) {
        const childProps = await mcp.getProperties(child.path);
        if (childProps.visible) return child.name;
      }
      return null;
    };

    const model1 = await getVisibleModel(p1Path);
    const model2 = await getVisibleModel(p2Path);

    expect(model1).toBeTruthy();
    expect(model2).toBeTruthy();
    expect(model1).toMatch(/^animal-/);
    expect(model2).toMatch(/^animal-/);
    expect(model1).not.toBe(model2);
  } finally {
    await context2.close();
  }
});
