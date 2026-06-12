import { expect } from '@playwright/test';
import type { TestInfo } from '@playwright/test';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { MCPBridge } from './mcp-bridge';

/**
 * Take a Godot screenshot via the MCP bridge and attach it to the
 * Playwright HTML report.
 *
 * @param mcp       - Connected MCPBridge instance
 * @param testInfo  - Playwright TestInfo from the current test
 * @param name      - Slug used for filename and attachment label (e.g. "plushie-joined")
 * @returns         - The screenshot command result { status, path, size }
 */
export async function godotScreenshot(
  mcp: MCPBridge,
  testInfo: TestInfo,
  name: string,
): Promise<{ status: string; path: string; size?: number[] }> {
  // Resolved from e2e/helpers/ → e2e/test-results/screenshots/
  const outDir = path.resolve(__dirname, '..', 'test-results', 'screenshots');
  fs.mkdirSync(outDir, { recursive: true });

  const filePath = path.join(outDir, `godot-${name}.png`);
  const result = await mcp.takeScreenshot(filePath);

  expect(result.status).toBe('ok');
  console.log(`Godot screenshot saved: ${result.path} (${result.size?.[0]}x${result.size?.[1]})`);

  await testInfo.attach(`godot-${name}`, {
    path: filePath,
    contentType: 'image/png',
  });

  return result;
}
