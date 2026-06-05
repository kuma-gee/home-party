## Source GDD

`gdd/DRAW_AND_GUESS.md#guessing-interface`, `gdd/DRAW_AND_GUESS.md#guess-submission`

## What to build

During the drawing phase, mobile players see a text input field with a "Submit" button on their phone. Typing a guess and hitting submit sends `guess;<text>` to Godot via the data channel. Godot compares the guess (case-insensitive) against the current word. Correct → sends `guess_result;correct` back to the phone (green flash) and broadcasts `player_guessed;<player_name>` to all clients for the shared screen. Incorrect → sends `guess_result;incorrect` (red flash) and the input clears for retry.

The phone UI shows only: guess input + submit button + brief colored flash feedback. No scoreboard, no timer, no drawing view — per the GDD.

Only the first correct guess from each player counts. Track who has already guessed correctly this round in Godot.

## Acceptance criteria

- [x] Mobile shows a text input + submit button during the drawing phase (hidden otherwise)
- [x] Submitting a guess sends `guess;<text>` to Godot via the data channel
- [x] Correct guess (case-insensitive match): phone flashes green screen briefly; first correct guess per player is tracked
- [x] Incorrect guess: phone flashes red briefly, input clears for retry
- [x] Already-guessed players cannot score again that round (no multiple guess farming)
- [x] `player_guessed_correctly` signal fires for the shared screen to display

## Blocked by

- `004-round-flow-and-word-assignment`
