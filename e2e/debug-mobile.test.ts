/**
 * Draw & Guess E2E tests.
 *
 * Tests the full game lifecycle: word submission, round flow, desktop UI,
 * VR drawing/erasing features, scoring, and game-over leaderboard.
 */
import { test } from '@playwright/test';
import { connectPlayer } from './helpers/player';
import { randomDelay } from './helpers/delay';

const PLAYER_UUIDS = [
  'e2e-draw-player-0001-0000-000000000001',
  'e2e-draw-player-0002-0000-000000000002',
  'e2e-draw-player-0003-0000-000000000003',
  'e2e-draw-player-0004-0000-000000000004',
  'e2e-draw-player-0005-0000-000000000005',
  'e2e-draw-player-0006-0000-000000000006',
  'e2e-draw-player-0007-0000-000000000007',
  'e2e-draw-player-0008-0000-000000000008',
];

test.describe('Debug Mobile Players', () => {
  test('connect mobile players', async ({ page }) => {
    const browser = page.context().browser()!;

    // Create separate browser contexts for players 2-8
    // (each needs its own localStorage for the client UUID)
    const contexts = [];
    const extraPages = [];
    for (let i = 0; i < 7; i++) {
      const ctx = await browser.newContext();
      contexts.push(ctx);
      extraPages.push(await ctx.newPage());
    }

    try {
      const pages = [page, ...extraPages];
      await Promise.all(
        pages.map(async (pw, i) => {
          await randomDelay(200, 5000);
          await connectPlayer(pw, PLAYER_UUIDS[i]);
        }),
      );

      await page.waitForTimeout(30_000);
    } finally {
      for (const ctx of contexts) {
        await ctx.close();
      }
    }
  });
});
