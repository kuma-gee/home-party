import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';
import {
  selectAndStartGame,
  vrPlayerReady,
  waitForNodeType,
  waitForJoinedPlayers,
} from './helpers/vr-player';
import { cleanupAfterGameScene } from './helpers/cleanup';
import { DRAW_AND_GUESS_PATH } from './helpers/constants';
import { randomDelay } from './helpers/delay';
import type { MCPBridge } from './helpers/mcp-bridge';

const PLAYER_UUIDS = [
  'e2e-draw-player-0001-0000-000000000001',
  'e2e-draw-player-0002-0000-000000000002',
  'e2e-draw-player-0003-0000-000000000003',
];

const SUBMITTED_WORDS = ['pizza', 'guitar', 'rocket'];
const INCORRECT_GUESS = 'wrongguess';

test.setTimeout(120_000);

/**
 * Poll the RoundManager until it reaches the expected phase value.
 * Phase enum: PRE_GAME=0, DRAWING=1, REVEALING=2, FINISHED=3
 */
async function waitForRoundPhase(
  mcp: MCPBridge,
  roundMgrPath: string,
  expectedPhase: number,
  timeoutMs = 15_000,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const props = await mcp.getProperties(roundMgrPath);
    if (props.phase === expectedPhase) return;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(
    `RoundManager did not reach phase ${expectedPhase} within ${timeoutMs}ms`,
  );
}

test.describe('Draw & Guess', () => {
  let gamePath: string;
  let roundMgrPath: string;
  let wordMgrPath: string;

  test.afterEach(async ({ mcp }) => {
    await cleanupAfterGameScene(mcp);
  });

  test('complete game flow with 3 mobile players', async ({ page, mcp }) => {
    const browser = page.context().browser()!;

    // Create separate browser contexts for player 2 and 3
    // (each needs its own localStorage for the client UUID)
    const context2 = await browser.newContext();
    const page2 = await context2.newPage();
    const context3 = await browser.newContext();
    const page3 = await context3.newPage();

    try {
      // ============================================================
      // Phase 1: Connection & Word Submission (Prepare Phase)
      // ============================================================

      // Connect all 3 mobile players in parallel with a random stagger
      const pages = [page, page2, page3];
      await Promise.all(
        pages.map(async (pw, i) => {
          await randomDelay(200, 1000); // stagger each player's connection
          await connectPlayer(pw, PLAYER_UUIDS[i]);
        }),
      );
      await page.waitForTimeout(1000);

      // VR player selects and starts Draw & Guess
      await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);

      // Wait for the game scene to load
      gamePath = await waitForNodeType(mcp, 'BaseGame', 25_000);
      await waitForJoinedPlayers(mcp, gamePath, 10_000, 3);

      wordMgrPath = `${gamePath}/WordManager`;
      roundMgrPath = `${gamePath}/RoundManager`;

      // ---- Assertion 1: 3 DrawPlayerUI nodes exist in the game scene ----
      const drawPlayers = (await mcp.listNodesByType('DrawPlayerUI')) as string[];
      expect(drawPlayers.length).toBe(3);

      const allPages = [page, page2, page3];

      // All players submit their words in parallel with randomised timing
      await Promise.all(
        allPages.map(async (pw, i) => {
          const word = SUBMITTED_WORDS[i];

          await randomDelay(300, 1200); // stagger start and initial thinking

          // Wait for WordInputLayout to appear (prepare phase)
          await pw.waitForSelector('.word-input-container', { timeout: 15_000 });

          // Player thinks about what word to submit
          await randomDelay(500, 2000);

          // Fill the word and submit
          await randomDelay(200, 800); // typing hesitation
          await pw.fill('input[type="text"]', word);
          await randomDelay(100, 500); // brief pause before clicking submit
          await pw.click('button:has-text("Submit")');

          // Wait for submitted confirmation (submitted-state)
          await pw.waitForSelector('.submitted-state', { timeout: 10_000 });
        }),
      );
      await page.waitForTimeout(500);

      // ---- Assertion 2: word_manager.size() == 3 ----
      const wordCount = await mcp.callMethod(wordMgrPath, 'size', []);
      expect(wordCount.result).toBe(3);

      // VR player starts the game (check_all_ready(true))
      await vrPlayerReady(mcp, gamePath);
      await page.waitForTimeout(2000);

      // ---- Assertion 3: is_game_phase == true ----
      const gameProps = await mcp.getProperties(gamePath);
      expect(gameProps.is_game_phase).toBe(true);

      // ============================================================
      // Phase 2: Game Rounds
      // ============================================================

      for (let round = 1; round <= 3; round++) {
        // Wait for round to be in DRAWING phase
        await waitForRoundPhase(mcp, roundMgrPath, 1 /* DRAWING */, 15_000);

        // ---- Assertion 4: round_manager.phase == 1 (DRAWING), current_round advances ----
        const roundProps = await mcp.getProperties(roundMgrPath);
        expect(roundProps.phase).toBe(1);
        expect(roundProps.current_round).toBe(round);

        const currentWord = roundProps.current_word as string;
        expect(currentWord).toBeTruthy();

        // ---- Assertion 4b: Round timer is visible on desktop during drawing phase ----
        const timerLabelPath = `${gamePath}/CanvasLayer/Control/GameUI/TimerLabel`;
        const timerProps = await mcp.getProperties(timerLabelPath);
        expect(timerProps.visible).toBe(true);
        expect(parseInt(timerProps.text, 10)).toBeGreaterThanOrEqual(0);


        // All players guess in parallel with randomised timing to simulate real gameplay
        await Promise.all(
          allPages.map(async (pw) => {
            // Stagger each player's start so they don't all act at the exact same moment
            await randomDelay(100, 600);

            // Wait for the input form to be visible (after reset)
            await pw.waitForSelector('.word-input-container', { timeout: 10_000 });

            // Player reads the drawing and thinks about their guess
            await randomDelay(800, 2500);

            // --- Incorrect guess (player types a wrong answer first) ---
            await randomDelay(200, 800); // typing hesitation
            await pw.fill('input[type="text"]', INCORRECT_GUESS);
            await randomDelay(100, 400); // brief pause before clicking submit
            await pw.click('button:has-text("Submit")');

            // ---- Assertion 5: feedback-overlay.incorrect appears ----
            await pw.waitForSelector('.feedback-overlay.incorrect', { timeout: 5_000 });
            // Player reads the "wrong" feedback and thinks before trying again
            await randomDelay(1500, 3500);

            // --- Correct guess ---
            await randomDelay(200, 800); // typing hesitation
            await pw.fill('input[type="text"]', currentWord);
            await randomDelay(100, 400); // brief pause before clicking submit
            await pw.click('button:has-text("Submit")');

            // ---- Assertion 6: feedback-overlay.correct appears ----
            await pw.waitForSelector('.feedback-overlay.correct', { timeout: 5_000 });
            // Player basks in the satisfaction of getting it right
            await randomDelay(800, 2000);
          }),
        );

        // ---- Assertion 6b: REVEALING phase shows the word on desktop ----
        await waitForRoundPhase(mcp, roundMgrPath, 2 /* REVEALING */, 5_000);
        const revealLabelPath = `${gamePath}/CanvasLayer/Control/GameUI/RevealLabel`;
        const revealProps = await mcp.getProperties(revealLabelPath);
        expect(revealProps.visible).toBe(true);
        expect(revealProps.text).toContain(currentWord);

        // ---- Assertion 7: round transitions (all 3 guessed correctly) ----
        if (round < 3) {
          // Phase goes: DRAWING(1) → REVEALING(2) → DRAWING(1) for next round
          await waitForRoundPhase(mcp, roundMgrPath, 1 /* DRAWING */, 15_000);

          // Verify we've advanced to the next round
          const nextProps = await mcp.getProperties(roundMgrPath);
          expect(nextProps.current_round).toBe(round + 1);
        }
      }

      // ============================================================
      // Phase 3: Game End
      // ============================================================

      // ---- Assertion 8: round_manager.phase == 3 (FINISHED) ----
      await waitForRoundPhase(mcp, roundMgrPath, 3 /* FINISHED */, 15_000);

      const finalProps = await mcp.getProperties(roundMgrPath);
      expect(finalProps.phase).toBe(3);
      expect(finalProps.current_round).toBe(3);

      // ---- Assertion 9: Scores exist for all 4 players (VR + 3 mobile) ----
      const scoringPath = `${roundMgrPath}/Scoring`;
      const scoresResult = await mcp.callMethod(scoringPath, 'get_scores', []);
      const scores = scoresResult.result as Array<{
        uuid: string;
        total_points: number;
        rounds_guessed_correctly: number;
      }>;
      expect(scores).toBeDefined();
      expect(scores.length).toBe(4);

      // VR player scored points
      const vrScore = scores.find((s) => s.uuid === 'vr_player');
      expect(vrScore).toBeDefined();
      expect(vrScore!.total_points).toBeGreaterThan(0);

      // Each mobile player scored points and guessed all 3 rounds
      for (const uuid of PLAYER_UUIDS) {
        const playerScore = scores.find((s) => s.uuid === uuid);
        expect(playerScore).toBeDefined();
        expect(playerScore!.total_points).toBeGreaterThan(0);
        expect(playerScore!.rounds_guessed_correctly).toBe(3);
      }
    } finally {
      // Close the extra browser contexts (not the main page's context)
      await context3.close();
      await context2.close();
    }
  });
});
