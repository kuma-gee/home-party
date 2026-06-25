# Draw & Guess

Mobile players all submit words into a shared pool. The VR player draws each
word in freeform 3D space while the 3D view is visible live on a shared desktop
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
2. **Drawing Phase (60s)**: VR player draws the word in freeform 3D space; the 3D view is visible live on the shared desktop screen
3. **Guessing Phase (concurrent)**: Mobile players type guesses on their phones while watching the shared screen
4. **Scoring**: When the timer expires, points are distributed based on guess order
5. **Repeat**: Next word is drawn — continues until all words are used

### Game End
After every submitted word has been drawn, the game ends and a **leaderboard** is
displayed showing all players ranked by total score.

## VR Player

The VR player draws **freely in 3D space** — no canvas, no boundaries. Lines and
shapes appear wherever they move the pen, creating a floating 3D sculpture that is
visible live on the shared desktop screen for everyone to see.

### Drawing Tools

| Tool     | Input                          | Behavior |
|----------|--------------------------------|----------|
| Brush    | Grip + trigger hold            | Draws a continuous 3D line while trigger is held. **3 brush sizes** available — Small (0.01), Medium (0.03), Large (0.06) — grab the desired brush from the back of the color palette |
| Color    | Dip brush tip into color swatch| Selects a new color from the palette |
| Eraser   | Touch lines with eraser        | Erases the line |
| Clear    | Hold brush in eraser for 3s    | Clears all drawn strokes |

### Color Palette

**6 colors** available on a grabbable floating palette beside the player:
- Black, Red, Blue, Green, Yellow, White (default)
- The palette can be grabbed and repositioned freely
- Current color is shown at the tip of the brush
- **3 brush sizes** (Small, Medium, Large) are stored on the back of the palette

### Word Display

The current word is displayed on a **private panel** visible only to the VR player.
The panel shows:
- The word to draw (large text)
- Round timer countdown (prominent)
- Word progress indicator (e.g., "Word 3 of 7")
- Skip button, to skip the current word

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

### Guessing Interface

**Mobile phone (input only)**:
- **Guess input**: Text field with submit button
- **Feedback**: Brief flash on screen for correct (green) or incorrect (red) guesses
- That's it — no drawing view, no scoreboard, no timer on the phone

**Shared desktop screen** shows everything else:
- **Live 3D view**: Real-time camera view of the VR player's drawing space from a fixed angle
- **Scoreboard**: Current scores of all players
- **Round timer**: Prominent countdown display
- **Word progress**: Current word number (e.g., "Word 3 of 7")

**Guess Submission**:
- Player types their guess on the phone and hits "Submit"
- Correct guess: phone flashes green
- Incorrect guess: phone flashes red briefly, input clears for retry
- No limit on number of guesses — spam away

### Player Pets (3D Representation)

Each mobile player is represented inside the 3D drawing room as a **cube-pet plushie**.
Pets sit on the floor in front of the drawing area and serve as a visual indicator of player status.

**Behavior during rounds:**
- **Idle:** Pets sit still
- **Correct guess:** model squishes, glows with the green color
- **Incorrect guess:** model squishes, glows with the red color
- **All guessed:** Once all players have guessed correctly, round advances

**VR interaction:** Pets are grabbable (`XRToolsPickable`) — the VR player can pick them up, move them around, and trigger a squeak sound by pressing the action button (same as lobby plushies).

**Desktop visibility:** Pets are visible on the shared desktop TV screen so mobile players can see their own (and others') pet reactions.

### Scoring

Points are awarded based on **guess order** — the faster you guess, the more you earn:

| Guess Order | Points |
|-------------|--------|
| 1st         | 5      |
| 2nd         | 4      |
| 3rd         | 3      |
| 4th         | 2      |
| 5th+        | 1      |

**Design Intent**: Creates a scramble where everyone has incentive to guess fast,
but late guessers still get something. The flat 1 point for 5th+ means there's
always a reason to keep trying even if you're behind.

## Leaderboard

After all words are drawn, a final leaderboard is displayed:

- **Ranked list** of all players by total score
- **VR player** is included in the rankings
- **Breakdown** shows each player's total points and how many rounds they guessed correctly
- **Highlight** the winner with a celebration animation

The leaderboard is shown on the shared desktop screen and in VR space. It is not displayed on phones — the phone remains a text input device only.

## Design Pillars

1. **Personal & hilarious**: Words come from the players themselves, leading to inside jokes and absurd combinations
2. **VR is the entertainer**: The fixed VR player is the show — their terrible (or amazing) 3D drawings are the main spectacle
3. **Everyone plays every round**: No one sits out — mobile players are always guessing or have contributed words
4. **Low friction, high chaos**: Simple rules, chaotic execution — the fun is in the mess
5. **Fair competition**: Sliding point scale means every round matters, even if you're not first
