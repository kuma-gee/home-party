## Source GDD

`gdd/DRAW_AND_GUESS.md#round-flow`, `gdd/DRAW_AND_GUESS.md#word-draw`, `gdd/DRAW_AND_GUESS.md#edge-cases`

## What to build

Implement the round lifecycle: after word collection, a random word is pulled from the pool and assigned to the VR player's private panel. A 60-second drawing timer starts. When the timer expires, the round ends: the word is revealed on the shared screen, scores are tallied (see 006), and the next word is pulled from the pool. This repeats until all words are exhausted, at which point the game transitions to the leaderboard state.

The word pool is a Godot array (`PoolStringArray` or `Array[String]`) managed by the game controller autoload. Words are removed from the pool as they are drawn. If the pool is empty but rounds remain (edge case when combined with skipped words), use the fallback dictionary (013).

No scoring logic yet — just end-of-round state transition and word tracking.

## Acceptance criteria

- [ ] On game start, a random word is pulled from the pool and assigned to the current round
- [ ] A 60-second countdown timer begins (visual feedback not required yet — just the internal clock)
- [ ] When timer expires, the current round ends and the word is revealed on the shared screen
- [ ] After a brief reveal delay (~5s), the next word is drawn — continues until pool is empty
- [ ] When all words are used, the game fires a `game_ended` signal (to be caught by leaderboard slice)
- [ ] Word progress is tracked internally (e.g., "word 3 of 7")

## Blocked by

- `001-game-scaffold-and-word-submission`
