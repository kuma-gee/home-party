import { test, expect } from './helpers/godot-fixture';
import { connectPlayer } from './helpers/player';

const PLAYER_MANAGER_PATH = '/root/PlayerManager';
const GAME_SHELVE_PATH = '/root/Staging/Scene/MenuWorld/GameShelve';

const DRAW_AND_GUESS_PATH = 'res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tres';
const CASTLE_DEFENSE_PATH = 'res://mods-unpacked/KumaGee-VRCore/castle-defense/castle_defense.tres';

const STATE_CONNECTED = 0;
const STATE_UNPLAYABLE = 1;
const UNPLAYABLE_LABEL_SUFFIX = '/HBoxContainer/UnplayableLabel';

const GAMEPAD_UUID = 'e2e-test-gamepad-0000-0000-000000000010';
const PHONE_UUID = 'e2e-test-phone-0000-0000-000000000011';

test.afterEach(async ({ mcp }) => {
  await mcp.callMethod(GAME_SHELVE_PATH, 'select_game_with_path', ['']);
  await mcp.callMethod(PLAYER_MANAGER_PATH, 'unregister_gamepad', [-1]);
  await mcp.callMethod(PLAYER_MANAGER_PATH, 'remove_all_players', []);
  await new Promise((r) => setTimeout(r, 500));
});

test('gamepad plushie shows UNPLAYABLE icon when phone-only game is selected', async ({ page, mcp }) => {
  await connectPlayer(page, PHONE_UUID);
  await page.waitForTimeout(1000);

  await mcp.callMethod(PLAYER_MANAGER_PATH, 'register_fake_gamepad', [GAMEPAD_UUID]);
  await page.waitForTimeout(1000);

  const allBodies = (await mcp.listNodesByType('RigidBody3D')) as string[];
  const plushiePaths = allBodies.filter((p) => p.includes('Plushie'));
  expect(plushiePaths).toHaveLength(2);

  const byUuid: Record<string, string> = {};
  for (const p of plushiePaths) {
    const props = await mcp.getProperties(p);
    byUuid[props.player_uuid as string] = p;
  }
  const gamepadPlushie = byUuid[GAMEPAD_UUID];
  const phonePlushie = byUuid[PHONE_UUID];
  expect(gamepadPlushie).toBeTruthy();
  expect(phonePlushie).toBeTruthy();

  const allJoinedPlayers = (await mcp.listNodesByType('JoinedPlayer')) as string[];
  const joinedByUuid: Record<string, string> = {};
  for (const p of allJoinedPlayers) {
    const props = await mcp.getProperties(p);
    joinedByUuid[props.uuid as string] = p;
  }
  const gamepadJoined = joinedByUuid[GAMEPAD_UUID];
  const phoneJoined = joinedByUuid[PHONE_UUID];
  expect(gamepadJoined).toBeTruthy();
  expect(phoneJoined).toBeTruthy();

  const gamepadIcon = `${gamepadPlushie}/UnplayableIcon`;
  const phoneIcon = `${phonePlushie}/UnplayableIcon`;

  // Both start CONNECTED
  expect((await mcp.getProperties(gamepadPlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(gamepadIcon)).visible).toBe(false);
  expect((await mcp.getProperties(phonePlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(phoneIcon)).visible).toBe(false);
  expect((await mcp.getProperties(`${gamepadJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);
  expect((await mcp.getProperties(`${phoneJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);

  // Select Draw & Guess (phone_only=true)
  await mcp.callMethod(GAME_SHELVE_PATH, 'select_game_with_path', [DRAW_AND_GUESS_PATH]);
  await page.waitForTimeout(500);

  // Gamepad plushie → UNPLAYABLE
  expect((await mcp.getProperties(gamepadPlushie))._state).toBe(STATE_UNPLAYABLE);
  expect((await mcp.getProperties(gamepadIcon)).visible).toBe(true);
  expect((await mcp.getProperties(`${gamepadJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(true);

  // Phone plushie → still CONNECTED
  expect((await mcp.getProperties(phonePlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(phoneIcon)).visible).toBe(false);
  expect((await mcp.getProperties(`${phoneJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);

  // Select Castle Defense (phone_only=false)
  await mcp.callMethod(GAME_SHELVE_PATH, 'select_game_with_path', [CASTLE_DEFENSE_PATH]);
  await page.waitForTimeout(500);

  // Both back to CONNECTED
  expect((await mcp.getProperties(gamepadPlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(gamepadIcon)).visible).toBe(false);
  expect((await mcp.getProperties(phonePlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(phoneIcon)).visible).toBe(false);
  expect((await mcp.getProperties(`${gamepadJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);
  expect((await mcp.getProperties(`${phoneJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);

  // Clear selection
  await mcp.callMethod(GAME_SHELVE_PATH, 'select_game_with_path', ['']);
  await page.waitForTimeout(500);

  // Both still CONNECTED
  expect((await mcp.getProperties(gamepadPlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(phonePlushie))._state).toBe(STATE_CONNECTED);
  expect((await mcp.getProperties(`${gamepadJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);
  expect((await mcp.getProperties(`${phoneJoined}${UNPLAYABLE_LABEL_SUFFIX}`)).visible).toBe(false);
});
