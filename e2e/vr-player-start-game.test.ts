import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';
import {
  selectAndStartGame,
  vrPlayerReady,
  markAllMobilePlayersReady,
  registerGamepadPlayer,
  waitForNodeType,
  waitForJoinedPlayers,
} from './helpers/vr-player';
import { cleanupAfterGameScene } from './helpers/cleanup';
import { DRAW_AND_GUESS_PATH, CASTLE_DEFENSE_PATH } from './helpers/constants';

const PHONE_UUID = 'e2e-test-vr-phone-0000-0000-000000000030';
const GAMEPAD_UUID = 'e2e-test-vr-gamepad-0000-0000-000000000032';

test.afterEach(async ({ mcp }) => {
  await cleanupAfterGameScene(mcp);
});

test.describe('VR player game lifecycle', () => {
  test('Draw & Guess: VR selects & starts game, then mobile + VR ready starts game', async ({
    page,
    mcp,
  }) => {
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);

    await selectAndStartGame(mcp, DRAW_AND_GUESS_PATH);

    const gamePath = await waitForNodeType(mcp, 'BaseGame', 25_000);
    await waitForJoinedPlayers(mcp, gamePath, 10_000);

    await markAllMobilePlayersReady(mcp);
    await page.waitForTimeout(500);

    await vrPlayerReady(mcp, gamePath);
    await page.waitForTimeout(2000);

    const props = await mcp.getProperties(gamePath);
    expect(props.is_game_phase).toBe(true);
  });

  test('Castle Defense: VR selects & starts game, then mobile + VR ready up', async ({
    page,
    mcp,
  }) => {
    await connectPlayer(page, PHONE_UUID);
    await page.waitForTimeout(1000);

    await registerGamepadPlayer(mcp, GAMEPAD_UUID);
    await page.waitForTimeout(1000);

    await selectAndStartGame(mcp, CASTLE_DEFENSE_PATH);

    const castlePath = await waitForNodeType(mcp, 'CastleDefense', 25_000);
    await waitForJoinedPlayers(mcp, castlePath, 10_000);

    await markAllMobilePlayersReady(mcp);
    await page.waitForTimeout(500);

    await vrPlayerReady(mcp, castlePath);
    await page.waitForTimeout(2000);

    // const playTimeProps = await mcp.getProperties(`${castlePath}/PlayTime`);
    // expect(playTimeProps.time_left).toBeGreaterThan(0);
  });
});
