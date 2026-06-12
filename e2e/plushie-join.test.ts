import { test, expect } from '@playwright/test';
import { MCPBridge } from './helpers/mcp-bridge';

const MCP = new MCPBridge(6008, '127.0.0.1');
const PLAYER_UUID = 'e2e-test-plushie-0000-0000-000000000001';

// Full path to the PlayerList UI node in the menu world scene
const PLAYER_LIST_PATH =
  '/root/Staging/Scene/MenuWorld/CanvasLayer/Control/MarginContainer/PlayerList';

test.beforeAll(async () => {
  await MCP.waitForReady(35_000);
});

/**
 * Helper: connect a mobile player via the game-client UI.
 * Sets localStorage with the given UUID, fills in the IP, clicks Connect,
 * and waits for the WebRTC data channel to open.
 */
async function connectPlayer(page: any, uuid: string) {
  await page.goto('/');
  await page.evaluate(([u]: [string]) => localStorage.setItem('clientId', u), [uuid]);
  await expect(page.locator('h2')).toHaveText('Connect to Game Server');
  await page.fill('#server-ip', 'localhost');
  await expect(page.locator('#server-ip')).toHaveValue('localhost');
  await page.locator('button', { hasText: 'Connect' }).click();
  await expect(page.locator('.spinner')).toBeVisible({ timeout: 10_000 });
  await expect(page.locator('.disconnect-icon')).toBeVisible({ timeout: 25_000 });
  // Give Godot time to process the connection and spawn the plushie
  await page.waitForTimeout(2000);
}

test('mobile player connects → plushie appears with correct identity', async ({ page }) => {
  // Navigate so the MenuWorld has fully loaded, THEN take the snapshot.
  // This way the diff only captures nodes added by the connection, not
  // the entire scene setup.
  await page.goto('/');
  // Wait for page to be stable before snapshot
  await page.waitForTimeout(2000);
  // Inject UUID AFTER the page loaded — this avoids any race with SvelteKit
  await page.evaluate(([u]: [string]) => localStorage.setItem('clientId', u), [PLAYER_UUID]);

  // Take MCP snapshot of the scene BEFORE connecting the player.
  // MenuWorld is fully loaded at this point.
  await MCP.takeSnapshot();

  // Connect the player
  await expect(page.locator('h2')).toHaveText('Connect to Game Server');
  await page.fill('#server-ip', 'localhost');
  await expect(page.locator('#server-ip')).toHaveValue('localhost');
  await page.locator('button', { hasText: 'Connect' }).click();
  await expect(page.locator('.spinner')).toBeVisible({ timeout: 10_000 });
  await expect(page.locator('.disconnect-icon')).toBeVisible({ timeout: 25_000 });
  await page.waitForTimeout(2000);

  // -----------------------------------------------------------------------
  // Verify the plushie was created in the Godot scene
  // -----------------------------------------------------------------------
  const diff = await MCP.getDiff();
  expect(diff.added).toBeDefined();
  console.log('Nodes added after connect:', JSON.stringify(diff.added, null, 2));
  expect(diff.added.length).toBeGreaterThanOrEqual(1);

  // PlushieSpawner calls Staging.add_scene_child(plushie), which adds the
  // plushie as a direct child of /root/Staging/Scene/.
  // The plushie's node name is "Plushie" (from plushie.tscn root).
  const plushiePaths = diff.added.filter(
    (p: string) =>
      p.startsWith('/root/Staging/Scene/') &&
      (p.endsWith('/Plushie') || p.includes('/Plushie@'))
  );
  expect(plushiePaths.length).toBeGreaterThanOrEqual(1);
  const plushiePath = plushiePaths[0];
  console.log(`Plushie node path: ${plushiePath}`);

  // Verify the type — the plushie script extends XRToolsPickable →
  // RigidBody3D. get_class() returns the engine class name.
  const plushieInfo = await MCP.getNode(plushiePath);
  // The root of plushie.tscn is an instance, so get_class returns the
  // extended engine class.
  expect(plushieInfo.type).toBe('RigidBody3D');

  // -----------------------------------------------------------------------
  // Verify the plushie carries the correct player identity
  // -----------------------------------------------------------------------
  const plushieProps = await MCP.getProperties(plushiePath);
  expect(plushieProps.player_uuid).toBe(PLAYER_UUID);
  expect(plushieProps.player_index).toBe(0);

  // The plushie's Label3D child should display "P1" (index 0 → P1)
  const tagPath = `${plushiePath}/PlayerTag`;
  const tagProps = await MCP.getProperties(tagPath);
  // Label3D stores its text in the `text` property
  expect(tagProps.text).toBe('P1');

  // -----------------------------------------------------------------------
  // Verify the PlayerList in Godot reports one active player
  // -----------------------------------------------------------------------
  const playerCount = await MCP.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
  expect(playerCount.result).toBe(1);

  // -----------------------------------------------------------------------
  // Screenshot for visual reference
  // -----------------------------------------------------------------------
  await page.screenshot({ path: 'test-results/screenshots/plushie-joined.png' });
});

test('disconnecting deactivates the player in Godot', async ({ page }) => {
  const uuid = 'e2e-test-plushie-0000-0000-000000000002';

  await connectPlayer(page, uuid);

  // Verify the player is active before disconnecting
  let playerCount = await MCP.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
  expect(playerCount.result).toBe(1);

  // -----------------------------------------------------------------------
  // Disconnect via the UI
  // -----------------------------------------------------------------------
  await page.locator('.disconnect-icon').click();

  // The connection form should reappear
  await expect(page.locator('h2')).toHaveText('Connect to Game Server', { timeout: 15_000 });

  // Wait for Godot to process the disconnection
  await page.waitForTimeout(2000);

  // -----------------------------------------------------------------------
  // Verify the player was deactivated in Godot
  // -----------------------------------------------------------------------
  playerCount = await MCP.callMethod(PLAYER_LIST_PATH, 'get_player_count', []);
  expect(playerCount.result).toBe(0);

  console.log('Player deactivated after disconnect. Player count:', playerCount.result);
});
