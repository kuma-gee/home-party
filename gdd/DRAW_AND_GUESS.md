# Draw & Guess

Mobile players all submit words into a shared pool. The VR player draws each
word in freeform 3D space while the drawing visible live on a shared desktop
screen (TV/monitor) for everyone to see. Mobile players race to type the correct
guess on their phones — the phone is purely a text input device.
Rounds end on a timer — the faster you guess, the more points you earn.
After all words are drawn, a leaderboard reveals the winner.

- **Round Time Limit:** 60 seconds
- **Win Condition:** Highest score after all words are drawn
- **Recommended Players:** 3–8

## Core Loop

Preparation, the game and the end are all inside a single scene without transitioning.

### Pre-Game: Word Collection
Each mobile player submits **1 word** into a shared pool. Words are hidden from
everyone. Words must be at least 3 characters long and are deduplicated automatically.
The game starts when all players have submitted their word and the VR player confirms ready.

### Round Flow
1. **Word Draw**: A random word is pulled from the pool and shown only to the VR player
2. **Drawing Phase (60s)**: VR player draws the word in freeform 3D space; the drawing is projected live on the shared desktop screen
3. **Guessing Phase (concurrent)**: Mobile players type guesses on their phones while watching the shared screen
4. **Scoring**: When the timer expires, points are distributed based on guess order
5. **Repeat**: Next word is drawn — continues until all words are used

### Game End
After every submitted word has been drawn, the game ends and a **leaderboard** is
displayed showing all players ranked by total score.

## VR Player

The VR player draws **freely in 3D space** — no canvas, no boundaries. Lines and
shapes appear wherever they move the pen, creating a floating 3D sculpture that is
projected live on the shared desktop screen for everyone to see.

### Drawing Tools

| Tool     | Input                          | Behavior |
|----------|--------------------------------|----------|
| Pen      | Grip + trigger hold            | Draws a continuous 3D line while trigger is held |
| Color    | Dip pen tip into color swatch  | Selects a new color from the palette floating beside the player |
| Eraser   | Flip controller upside-down    | Erases the last stroke on release |
| Clear    | Two-hand grab + pull apart     | Clears all drawn strokes (confirmation gesture) |

### Color Palette

**6 colors** available on a grabbable floating palette beside the player:
- Black (default), Red, Blue, Green, Yellow, White
- The palette can be grabbed and repositioned freely
- Current color is shown by a glowing ring around the selected swatch

### Word Display

The current word is displayed on a **private floating panel** visible only to the VR player.
The panel shows:
- The word to draw (large text)
- Round timer countdown (prominent)
- Current score of all players (small, bottom corner)
- Word progress indicator (e.g., "Word 3 of 7")

### Skip

The VR player can press Skip to discard the current word and draw a new one
from the pool. The skipped round ends immediately with no points awarded.
If skip is used on the last remaining word, the game ends.

### VR Scoring

The VR player earns points based on how well they communicated the word:

| Players who guessed | Points |
|--------------------|--------|
| All players        | 5      |
| 75%+ of players    | 4      |
| 50–74% of players  | 3      |
| 25–49% of players  | 2      |
| 1–24% of players   | 1      |
| Nobody guessed     | 0      |

**Speed bonus**: If the first guess comes in under 15 seconds, the VR player gets **+1 bonus point**.

**Design Intent**: Rewards the VR player for being clear and creative, not for being
obscure. The speed bonus encourages drawing recognizable forms quickly.

## Mobile Players

### Pre-Game: Word Submission

When joining the lobby, each mobile player sees a text input field and is prompted
to submit 1 word. The UI shows:
- Text input with character counter (min 3, max 20)
- "Ready" button appears after word is submitted

**Word Validation**:
- Minimum 3 characters
- Maximum 20 characters
- Alphanumeric only (no special characters)
- Duplicates: if a word already exists in the pool, the player sees an error message and must submit a different word
- If the pool has fewer than 5 words after all submissions, a fallback dictionary fills the gap

### Guessing Interface

**Mobile phone (input only)**:
- **Guess input**: Text field with submit button
- **Feedback**: Brief flash on screen for correct (green) or incorrect (red) guesses
- That's it — no drawing view, no scoreboard, no timer on the phone

**Shared desktop screen** shows everything else:
- **Live drawing**: 2D projection of the VR player's 3D drawing, updating in real-time
- **Scoreboard**: Current scores of all players
- **Round timer**: Prominent countdown display
- **Guess progress**: Shows how many players have guessed correctly (e.g., "3/6 guessed")
- **Word progress**: Current word number (e.g., "Word 3 of 7")
- **Winner alerts**: When someone guesses correctly, their name and guess rank pop up

**Guess Submission**:
- Player types their guess on the phone and hits "Submit"
- Correct guess: phone flashes green; name and rank appear on the shared screen ("Alice — 1st!")
- Incorrect guess: phone flashes red briefly, input clears for retry
- No limit on number of guesses — spam away

### Scoring

Points are awarded based on **guess order** — the faster you guess, the more you earn:

| Guess Order | Points |
|-------------|--------|
| 1st         | 5      |
| 2nd         | 4      |
| 3rd         | 3      |
| 4th         | 2      |
| 5th+        | 1      |

Only the first correct guess from each player counts — you can't farm points by
guessing the same word repeatedly.

**Design Intent**: Creates a scramble where everyone has incentive to guess fast,
but late guessers still get something. The flat 1 point for 5th+ means there's
always a reason to keep trying even if you're behind.

## Leaderboard

After all words are drawn, a final leaderboard is displayed:

- **Ranked list** of all players by total score
- **VR player** is included in the rankings
- **Breakdown** shows each player's total points and how many rounds they guessed correctly
- **Highlight** the winner with a celebration animation

The leaderboard is shown on the shared desktop screen and in VR space.

## Edge Cases

- **VR player disconnects**: Game ends immediately, current scores are finalized, leaderboard is shown
- **Mobile player disconnects**: Their submitted word remains in the pool; they can rejoin at any time during pre-game or mid-game. On rejoin, their submitted word state is restored (pre-game) or they are placed into guess mode with their current round progression intact (mid-game)
- **Word pool exhausted**: If all words have been used, the fallback dictionary activates for remaining rounds
- **Nobody guesses a word**: VR player gets 0 points for that round, word is revealed, game moves on
- **Only 2 players**: VR draws, 1 mobile guesses — functional but less competitive; recommend 3+
- **VR player draws something unrecognizable**: That's the fun — no penalty, just a harder round

## Design Pillars

1. **Personal & hilarious**: Words come from the players themselves, leading to inside jokes and absurd combinations
2. **VR is the entertainer**: The fixed VR player is the show — their terrible (or amazing) 3D drawings are the main spectacle
3. **Everyone plays every round**: No one sits out — mobile players are always guessing or have contributed words
4. **Low friction, high chaos**: Simple rules, chaotic execution — the fun is in the mess
5. **Fair competition**: Sliding point scale means every round matters, even if you're not first
