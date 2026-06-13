import { test as base, expect } from '@playwright/test';
import { MCPBridge } from './mcp-bridge';
import { godotScreenshot } from './screenshot';
import { waitForMenuWorld } from './player';

function fmtSceneTree(node: any, indent = ''): string {
  const line = `${indent}${node.path}  [${node.type}]`;
  if (!node.children?.length) return line;
  return line + '\n' + node.children.map((c: any) => fmtSceneTree(c, indent + '  ')).join('\n');
}

type WorkerFixtures = {
  /** Worker-scoped MCP bridge — connects once per worker before any tests run. */
  workerMCP: MCPBridge;
};

type TestFixtures = {
  /** Test-scoped MCP bridge. Automatically takes a Godot screenshot on failure. */
  mcp: MCPBridge;
};

/**
 * Extended `test` with:
 * - `workerMCP` — connects to the Godot MCP bridge once per worker and waits
 *   for the MenuWorld to be ready.
 * - `mcp` — provides the same bridge per-test, and captures a Godot viewport
 *   screenshot when the test fails (attached to the Playwright HTML report).
 */
export const test = base.extend<TestFixtures, WorkerFixtures>({
  workerMCP: [
    async ({}, use) => {
      const bridge = new MCPBridge(6008, '127.0.0.1');
      await bridge.waitForReady(35_000);
      await waitForMenuWorld(bridge, 15_000);
      await use(bridge);
    },
    { scope: 'worker' },
  ],

  mcp: async ({ workerMCP }, use, testInfo) => {
    try {
      await use(workerMCP);
    } finally {
      if (testInfo.status !== testInfo.expectedStatus) {
        try {
          const name = testInfo.title.replace(/\s+/g, '-').toLowerCase();
          await godotScreenshot(workerMCP, testInfo, name);
        } catch (e) {
          console.warn('Failed to take Godot screenshot on failure:', e);
        }
        try {
          const tree = await workerMCP.getSceneTree();
          console.log('Scene tree on failure:\n' + fmtSceneTree(tree));
        } catch (e) {
          console.warn('Failed to get scene tree on failure:', e);
        }
      }
    }
  },
});

export { expect };
