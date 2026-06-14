/**
 * Shared constants for E2E tests.
 *
 * Godot node paths, game resource paths, and player state values
 * used across multiple test files.
 */

// ─── Core Godot node paths ───────────────────────────────────────────
export const PLAYER_MANAGER_PATH = '/root/PlayerManager';
export const STAGING_PATH = '/root/Staging';
export const MENU_WORLD_PATH = '/root/Staging/Scene/MenuWorld';
export const GAME_SHELVE_PATH = '/root/Staging/Scene/MenuWorld/GameShelve';

// ─── Mini-game resource paths ────────────────────────────────────────
export const DRAW_AND_GUESS_PATH =
  'res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tres';
export const CASTLE_DEFENSE_PATH =
  'res://mods-unpacked/KumaGee-VRCore/castle-defense/castle_defense.tres';

// ─── Plushie state enum values ───────────────────────────────────────
/** Plushie is connected and playable. */
export const STATE_CONNECTED = 0;
/** Plushie is connected but cannot play the selected game. */
export const STATE_UNPLAYABLE = 1;
