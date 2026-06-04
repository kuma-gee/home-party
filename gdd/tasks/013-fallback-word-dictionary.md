## Source GDD

`gdd/DRAW_AND_GUESS.md#word-validation` (fallback), `gdd/DRAW_AND_GUESS.md#edge-cases` (Word pool exhausted)

## What to build

After all mobile players have submitted their words, if the total pool size is less than 5, fill the remaining slots from a hardcoded dictionary of common English words included as a resource file in the Godot project. The dictionary is a simple text file (one word per line) loaded at init. Words from the dictionary are added to fill up to a minimum pool of 5 words (to ensure a minimum game length of 5 rounds).

Also handle the edge case where the word pool is exhausted mid-game (all words have been drawn/skipped): re-fill from the dictionary to keep the game going. This can happen if the pool was small and the VR player skipped many words.

## Acceptance criteria

- [ ] A hardcoded dictionary of common English words exists as a `.txt` resource in the mod
- [ ] After all mobile submissions, if pool < 5 words, dictionary words fill the gap
- [ ] If pool is exhausted during gameplay (all words drawn/skipped), dictionary refills it
- [ ] Dictionary words are valid (alphanumeric, same validation rules)
- [ ] Fallback words do not override player-submitted words

## Blocked by

- `001-game-scaffold-and-word-submission`
