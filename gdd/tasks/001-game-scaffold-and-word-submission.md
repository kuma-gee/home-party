## Source GDD

`gdd/DRAW_AND_GUESS.md#pre-game-word-collection`, `gdd/DRAW_AND_GUESS.md#word-validation`

## What to build

Create the game registration (`draw_and_guess.tres`) and a minimal scene that starts with the word-collection pre-game phase. Create a new layout in the game-client for mobile players to see a text input (3–20 chars, alphanumeric-only) and submit one word each. Godot validates, deduplicates, and stores words in a pool. The VR player sees a waiting state with a "Ready" confirmation button. The game starts once all mobile players have submitted and the VR player confirms. Its all in one scene without transitioning.

Define a new WebRPC message from phone to Godot: `word;<text>` (string). Godot responds with `word_ack;<ok|duplicate|invalid>` for validation feedback. The phone shows an error banner on duplicate/invalid and clears the input for retry.

## Acceptance criteria

- [x] Game resource `.tres` file registers "Draw & Guess" in the shelf with a placeholder scene
- [x] Mobile phone shows a word input field with character counter (min 3, max 20) and submit button
- [x] Words are sent to Godot via `word;<text>` and validated (alphanumeric, length, dedup)
- [x] Duplicate/invalid words show an error on the phone; valid words are accepted and the phone shows "Word submitted"
- [x] VR player sees a waiting panel with player count and a "Ready" button
- [x] When all mobile players have submitted and VR confirms ready, the game starts and mobile players see a text input for submitting guesses

## Blocked by

None - can start immediately
