import { expect, type Page } from '@playwright/test';
import { MCPBridge } from './mcp-bridge';

/** Root node of the MenuWorld inside the Staging scene tree. */
const MENU_WORLD_PATH = '/root/Staging/Scene/MenuWorld';

/**
 * Poll the MCP bridge until the MenuWorld scene node is present in the
 * Godot scene tree.  MenuWorld is loaded immediately on game start by
 * the Staging autoload, so this is usually fast once the bridge is ready.
 */
export async function waitForMenuWorld(
  mcp: MCPBridge,
  timeoutMs = 30_000,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const node = await mcp.getNode(MENU_WORLD_PATH);
    if (node?.type) return;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`MenuWorld did not load within ${timeoutMs}ms`);
}

/**
 * Navigate to the game page and set the player UUID in localStorage.
 */
export async function navigateToGame(page: Page, uuid: string): Promise<void> {
  await page.goto('/');
  await page.evaluate(([u]: [string]) => localStorage.setItem('clientId', u), [uuid]);
}

/**
 * Fill in the server IP, click Connect, and wait for the WebRTC data channel to open.
 */
export async function connectMobilePlayer(page: Page): Promise<void> {
  await expect(page.locator('h2')).toHaveText('Connect to Game Server');
  await page.fill('#server-ip', 'localhost');
  await expect(page.locator('#server-ip')).toHaveValue('localhost');
  await page.locator('button', { hasText: 'Connect' }).click();
  await expect(page.locator('.spinner')).toBeVisible({ timeout: 10_000 });
  await expect(page.locator('.disconnect-icon')).toBeVisible({ timeout: 25_000 });
  await page.waitForTimeout(2000);
}

/**
 * Convenience wrapper: navigate, set UUID, then connect.
 */
export async function connectPlayer(page: Page, uuid: string): Promise<void> {
  await navigateToGame(page, uuid);
  await connectMobilePlayer(page);
}
