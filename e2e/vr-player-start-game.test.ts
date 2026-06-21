/**
 * Draw & Guess E2E tests.
 *
 * Tests the full game lifecycle: word submission, round flow, desktop UI,
 * VR drawing/erasing features, scoring, and game-over leaderboard.
 */
import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';
import {
  selectAndStartGame,
  waitForNodeType,
  waitForJoinedPlayers,
} from './helpers/vr-player';
import { cleanupAfterGameScene } from './helpers/cleanup';
import { DRAW_AND_GUESS_PATH } from './helpers/constants';
import type { MCPBridge } from './helpers/mcp-bridge';

const PHONE_UUID = 'e2e-draw-phone-0001-0000-000000000001';
const PHONE_UUID_2 = 'e2e-draw-phone-0002-0000-000000000002';

test.setTimeout(120_000);

// ─── Helpers ──────────────────────────────────────────────────────────

async function getDrawPath(mcp: MCPBridge): Promise<string> {
  return await waitForNodeType(mcp, 'DrawAndGuess', 25_000);
}

async function getDrawProp(mcp: MCPBridge, gamePath: string, rel: string, prop: string): Promise<any> {
  return (await mcp.getProperties(`${gamePath}/${rel}`))[prop];
}

/** Find a JoinedPlayer/DrawPlayerUI node by uuid under the given game path. */
async function findPlayerUI(mcp: MCPBridge, gamePath: string, uuid: string): Promise<string | null> {
  const players = (await mcp.listNodesByType('JoinedPlayer')) as string[];
  for (const p of players) {
    if (!p.startsWith(gamePath)) continue;
    const pp = await mcp.getProperties(p);
    if (pp.uuid === uuid) return p;
  }
  return null;
}

/**
 * Submit a word on behalf of a phone player during the prepare phase.
 * We emit the `guessed` signal on the player's DrawPlayerUI, which the
 * game routes to word submission when not in game phase.
 */
async function submitWord(mcp: MCPBridge, playerUIPath: string, word: string): Promise<void> {
  await mcp.callMethod(playerUIPath, 'emit_signal', ['guessed', word]);
  await new Promise((r) => setTimeout(r, 300));
}

/**
 * Make a guess on behalf of a phone player during a round.
 * Emits the `guessed` signal which the game evaluates as a guess.
 */
async function makeGuess(mcp: MCPBridge, playerUIPath: string, guess: string): Promise<void> {
  await mcp.callMethod(playerUIPath, 'emit_signal', ['guessed', guess]);
  await new Promise((r) => setTimeout(r, 300));
}

/**
 * Start the game (transition from prepare to game phase).
 * Mark all mobile players ready (if not already), then signal VR player ready.
 */
async function startGame(mcp: MCPBridge, gamePath: string): Promise<void> {
  // Call check_all_ready(true) on the game scene (simulates VR player pressing Start)
  await mcp.callMethod(gamePath, 'check_all_ready', [true]);
  await new Promise((r) => setTimeout(r, 1000));
}

// ─── Tests ────────────────────────────────────────────────────────────

test.describe('Draw & Guess', () => {
  test.afterEach(async ({ mcp }) => {
    await cleanupAfterGameScene(mcp);
  });

  test('full lifecycle: single phone player prepares, submits word, game starts, guess completes all rounds', async ({
    page, mcp,
  }) => {
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);
    await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);
    const gamePath = await getDrawPath(mcp);
    await waitForJoinedPlayers(mcp, gamePath, 10_000);

    // ── Prepare Phase ──────────────────────────────────────────────
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/PrepareUI', 'visible')).toBe(true);
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/GameUI', 'visible')).toBe(false);
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/DesktopGameover', 'visible')).toBe(false);

    // No words submitted yet
    expect((await mcp.getProperties(`${gamePath}/WordManager`)).word_pool).toHaveLength(0);

    // Find player UI and submit a word
    const playerUI = await findPlayerUI(mcp, gamePath, PHONE_UUID);
    expect(playerUI).toBeTruthy();

    await submitWord(mcp, playerUI!, 'testword');

    // Verify word was accepted
    const wordPool = (await mcp.getProperties(`${gamePath}/WordManager`)).word_pool as string[];
    expect(wordPool).toHaveLength(1);
    expect(wordPool[0]).toBe('testword');

    // Player should be marked ready after word submission
    expect((await mcp.getProperties(playerUI!)).is_ready).toBe(true);

    // ── Start Game ─────────────────────────────────────────────────
    expect((await mcp.getProperties(gamePath)).is_game_phase).toBe(false);

    await startGame(mcp, gamePath);

    // Verify transition to game phase
    expect((await mcp.getProperties(gamePath)).is_game_phase).toBe(true);
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/PrepareUI', 'visible')).toBe(false);
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/GameUI', 'visible')).toBe(true);

    // ── Round 1 ────────────────────────────────────────────────────

    // Verify round manager state
    const rmProps = await mcp.getProperties(`${gamePath}/RoundManager`);
    expect(rmProps.current_round).toBe(1);
    expect(rmProps.total_rounds).toBe(1); // 1 word in pool
    expect(rmProps.phase).toBe(1); // Phase.DRAWING
    expect(rmProps.current_word).toBe('testword');

    // Progress label should show "Word 1 of 1"
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/GameUI/ProgressLabel', 'text')).toBe('Word 1 of 1');

    // Timer should be running
    const roundTimerProps = await mcp.getProperties(`${gamePath}/RoundManager/RoundTimer`);
    expect(roundTimerProps.time_left).toBeGreaterThan(0);
    expect(roundTimerProps.time_left).toBeLessThanOrEqual(60);

    // ── Guess Correctly ────────────────────────────────────────────

    // Player hasn't guessed yet
    expect(rmProps.guessed_players).toHaveLength(0);

    await makeGuess(mcp, playerUI!, 'testword');

    // Verify correct guess
    const rmPropsAfterGuess = await mcp.getProperties(`${gamePath}/RoundManager`);
    expect(rmPropsAfterGuess.guessed_players).toHaveLength(1);
    expect(rmPropsAfterGuess.guessed_players[0]).toBe(PHONE_UUID);

    // Player should be marked as guessed correctly
    expect((await mcp.getProperties(playerUI!)).has_guessed_correctly).toBe(true);

    // All guessed -> round ends early -> reveal phase
    expect(rmPropsAfterGuess.phase).toBe(2); // Phase.REVEALING

    // Reveal label shown
    const revealLabelText = await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/GameUI/RevealLabel', 'text');
    expect(revealLabelText).toContain('testword');
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/GameUI/RevealLabel', 'visible')).toBe(true);

    // Timer stopped after all guessed
    const roundTimerAfter = await mcp.getProperties(`${gamePath}/RoundManager/RoundTimer`);
    expect(roundTimerAfter.time_left).toBe(0);

    // ── Game Over (all words used) ─────────────────────────────────
    // Speed up: trigger reveal timer to finish -> _start_next_round() -> word pool empty -> _end_game()
    await mcp.callMethod(`${gamePath}/RoundManager/RevealTimer`, 'emit_signal', ['timeout']);
    await new Promise((r) => setTimeout(r, 500));

    // Verify game-over UI
    expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/DesktopGameover', 'visible')).toBe(true);

    // Round manager should be FINISHED
    expect((await mcp.getProperties(`${gamePath}/RoundManager`)).phase).toBe(3); // Phase.FINISHED

    // Verify scoring entries exist
    const scores = (await mcp.callMethod(`${gamePath}/RoundManager/Scoring`, 'get_scores', [])).result as any[];
    expect(scores.length).toBeGreaterThanOrEqual(1);
    const phoneScore = scores.find((s: any) => s.uuid === PHONE_UUID);
    expect(phoneScore).toBeTruthy();
    expect(phoneScore.total_points).toBeGreaterThanOrEqual(0);
    expect(phoneScore.rounds_guessed_correctly).toBe(1);
  });

  test('VR drawing features: pen and eraser respond to MCP method calls', async ({
    page, mcp,
  }) => {
    // Start a game so the scene with drawing tools is loaded
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);
    await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);
    const gamePath = await getDrawPath(mcp);
    await waitForJoinedPlayers(mcp, gamePath, 10_000);

    const penPath = `${gamePath}/BaseSceneContent/Pen`;
    const eraserPath = `${gamePath}/BaseSceneContent/EraserTool`;

    // ── Pen exists and has expected properties ─────────────────────
    const penNode = await mcp.getNode(penPath);
    expect(penNode).toBeTruthy();
    expect(penNode.type).toBe('VR3DPen');

    // Default state
    let penProps = await mcp.getProperties(penPath);
    expect(penProps.is_drawing).toBe(false);
    expect(typeof penProps.line_thickness).toBe('number');
    expect(penProps.line_thickness).toBe(0.03);
    expect(penProps.line_color).toBeTruthy();

    // Enable drawing
    await mcp.callMethod(penPath, 'set_drawing_enabled', [true]);
    penProps = await mcp.getProperties(penPath);
    expect(penProps.is_drawing).toBe(true);

    // Disable drawing
    await mcp.callMethod(penPath, 'set_drawing_enabled', [false]);
    penProps = await mcp.getProperties(penPath);
    expect(penProps.is_drawing).toBe(false);

    // Calling set_drawing_enabled(false) while already disabled is a no-op
    await mcp.callMethod(penPath, 'set_drawing_enabled', [false]);
    penProps = await mcp.getProperties(penPath);
    expect(penProps.is_drawing).toBe(false);

    // ── Line thickness can be set ──────────────────────────────────
    await mcp.callMethod(penPath, 'set', ['line_thickness', 0.05]);
    penProps = await mcp.getProperties(penPath);
    expect(penProps.line_thickness).toBe(0.05);

    // Reset
    await mcp.callMethod(penPath, 'set', ['line_thickness', 0.03]);
    penProps = await mcp.getProperties(penPath);
    expect(penProps.line_thickness).toBe(0.03);

    // ── Eraser tool exists and has expected state ──────────────────
    const eraserNode = await mcp.getNode(eraserPath);
    expect(eraserNode).toBeTruthy();
    expect(eraserNode.type).toBe('EraserTool');

    const eraserProps = await mcp.getProperties(eraserPath);
    expect(eraserProps.is_erasing).toBe(false);
  });

  test('word submission validation: rejects invalid and duplicate words', async ({
    page, mcp,
  }) => {
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);
    await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);
    const gamePath = await getDrawPath(mcp);
    await waitForJoinedPlayers(mcp, gamePath, 10_000);

    const playerUI = await findPlayerUI(mcp, gamePath, PHONE_UUID);
    expect(playerUI).toBeTruthy();

    const wordManagerPath = `${gamePath}/WordManager`;

    // ── Invalid: too short (less than 3 chars) ────────────────────
    // Submit a 1-char "word" – it should be INVALID
    // The game accepts the signal then checks the word in submit_word
    await submitWord(mcp, playerUI!, 'ab');
    await new Promise((r) => setTimeout(r, 200));
    // Word pool should still be empty
    expect((await mcp.getProperties(wordManagerPath)).word_pool).toHaveLength(0);

    // ── Invalid: special characters ─────────────────────────────────
    // The regex ^[a-zA-Z0-9]+$ rejects non-alphanumeric words
    await submitWord(mcp, playerUI!, 'hello!!!');
    await new Promise((r) => setTimeout(r, 200));
    expect((await mcp.getProperties(wordManagerPath)).word_pool).toHaveLength(0);

    // ── Valid word accepted ─────────────────────────────────────────
    await submitWord(mcp, playerUI!, 'apple');
    await new Promise((r) => setTimeout(r, 200));
    let pool = (await mcp.getProperties(wordManagerPath)).word_pool as string[];
    expect(pool).toHaveLength(1);
    expect(pool[0]).toBe('apple');

    // ── Invalid: too long (over 20 chars) ──────────────────────────
    await submitWord(mcp, playerUI!, 'thiswordiswaytoolongggg');
    await new Promise((r) => setTimeout(r, 200));
    pool = (await mcp.getProperties(wordManagerPath)).word_pool as string[];
    expect(pool).toHaveLength(1); // Still only "apple"

    // ── Duplicate word rejected ─────────────────────────────────────
    // Submit "apple" again – should be DUPLICATE
    await submitWord(mcp, playerUI!, 'apple');
    await new Promise((r) => setTimeout(r, 200));
    pool = (await mcp.getProperties(wordManagerPath)).word_pool as string[];
    expect(pool).toHaveLength(1); // Still only one "apple"

    // ── Case-insensitive duplicate check ────────────────────────────
    // "Apple" (capital A) should be detected as duplicate since the
    // word manager lowercases for comparison.
    await submitWord(mcp, playerUI!, 'Apple');
    await new Promise((r) => setTimeout(r, 200));
    pool = (await mcp.getProperties(wordManagerPath)).word_pool as string[];
    expect(pool).toHaveLength(1);
  });

  test('multiple players: two phone players submit words, both guess correctly', async ({
    page, mcp,
  }) => {
    const browser = page.context().browser()!;
    const context2 = await browser.newContext();
    const page2 = await context2.newPage();

    try {
      await connectPlayer(page, PHONE_UUID);
      await connectPlayer(page2, PHONE_UUID_2);
      await page.waitForTimeout(1500);

      await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);
      const gamePath = await getDrawPath(mcp);
      await waitForJoinedPlayers(mcp, gamePath, 10_000, 2);

      // ── Both players submit words ────────────────────────────────
      const p1UI = await findPlayerUI(mcp, gamePath, PHONE_UUID);
      const p2UI = await findPlayerUI(mcp, gamePath, PHONE_UUID_2);
      expect(p1UI).toBeTruthy();
      expect(p2UI).toBeTruthy();

      // Player 1 submits "planet"
      await submitWord(mcp, p1UI!, 'planet');
      await new Promise((r) => setTimeout(r, 200));

      // Player 2 submits "galaxy"
      await submitWord(mcp, p2UI!, 'galaxy');
      await new Promise((r) => setTimeout(r, 200));

      const wordPool = (await mcp.getProperties(`${gamePath}/WordManager`)).word_pool as string[];
      expect(wordPool).toHaveLength(2);
      expect(wordPool).toContain('planet');
      expect(wordPool).toContain('galaxy');

      // Both players marked ready
      expect((await mcp.getProperties(p1UI!)).is_ready).toBe(true);
      expect((await mcp.getProperties(p2UI!)).is_ready).toBe(true);

      // ── Start game ───────────────────────────────────────────────
      await startGame(mcp, gamePath);
      expect((await mcp.getProperties(gamePath)).is_game_phase).toBe(true);

      // One of the two words is selected (random). Check round state.
      const rmProps = await mcp.getProperties(`${gamePath}/RoundManager`);
      expect(rmProps.current_round).toBe(1);
      expect(rmProps.total_rounds).toBe(2); // 2 words in pool
      expect(rmProps.phase).toBe(1); // DRAWING
      const currentWord = rmProps.current_word as string;
      expect(['planet', 'galaxy']).toContain(currentWord);

      // ── Both players guess correctly ─────────────────────────────
      expect(rmProps.guessed_players).toHaveLength(0);

      // Player 1 guesses correctly
      await makeGuess(mcp, p1UI!, currentWord);
      await new Promise((r) => setTimeout(r, 200));

      let rmAfter = await mcp.getProperties(`${gamePath}/RoundManager`);
      expect(rmAfter.guessed_players).toHaveLength(1);
      // Player 1 should have "has_guessed_correctly = true"
      expect((await mcp.getProperties(p1UI!)).has_guessed_correctly).toBe(true);

      // Player 2 guesses correctly (now all have guessed)
      await makeGuess(mcp, p2UI!, currentWord);
      await new Promise((r) => setTimeout(r, 200));

      rmAfter = await mcp.getProperties(`${gamePath}/RoundManager`);
      expect(rmAfter.guessed_players).toHaveLength(2);
      expect(rmAfter.guessed_players).toContain(PHONE_UUID);
      expect(rmAfter.guessed_players).toContain(PHONE_UUID_2);
      expect((await mcp.getProperties(p2UI!)).has_guessed_correctly).toBe(true);

      // Round should now be in REVEALING phase
      expect(rmAfter.phase).toBe(2);

      // ── Advance to round 2 ───────────────────────────────────────
      await mcp.callMethod(`${gamePath}/RoundManager/RevealTimer`, 'emit_signal', ['timeout']);
      await new Promise((r) => setTimeout(r, 800));

      // Round 2 should be started with remaining word
      const rmRound2 = await mcp.getProperties(`${gamePath}/RoundManager`);
      expect(rmRound2.current_round).toBe(2);
      expect(rmRound2.total_rounds).toBe(2);
      expect(rmRound2.phase).toBe(1); // DRAWING
      const word2 = rmRound2.current_word as string;
      expect(['planet', 'galaxy']).toContain(word2);
      expect(word2).not.toBe(currentWord); // Should be the other word

      // Both players guess correctly in round 2
      await makeGuess(mcp, p1UI!, word2);
      await makeGuess(mcp, p2UI!, word2);
      await new Promise((r) => setTimeout(r, 200));

      // ── End game (all words used) ────────────────────────────────
      await mcp.callMethod(`${gamePath}/RoundManager/RevealTimer`, 'emit_signal', ['timeout']);
      await new Promise((r) => setTimeout(r, 500));

      // Verify game over
      expect(await getDrawProp(mcp, gamePath, 'CanvasLayer/Control/DesktopGameover', 'visible')).toBe(true);
      expect((await mcp.getProperties(`${gamePath}/RoundManager`)).phase).toBe(3); // FINISHED

      // Check scoring – both players should have scored in both rounds
      const scores = (await mcp.callMethod(`${gamePath}/RoundManager/Scoring`, 'get_scores', [])).result as any[];
      const p1Score = scores.find((s: any) => s.uuid === PHONE_UUID);
      const p2Score = scores.find((s: any) => s.uuid === PHONE_UUID_2);
      expect(p1Score).toBeTruthy();
      expect(p2Score).toBeTruthy();
      // Both guessed correctly in both rounds (2 rounds each)
      expect(p1Score.rounds_guessed_correctly).toBe(2);
      expect(p2Score.rounds_guessed_correctly).toBe(2);
      // First guesser gets more points per round (index 0 = 5 pts, index 1 = 4 pts)
      // Total per player should be 5 + 4 = 9 or 4 + 5 = 9 depending on who guessed first each round
      expect(p1Score.total_points + p2Score.total_points).toBe(18);
    } finally {
      await context2.close();
    }
  });
});
