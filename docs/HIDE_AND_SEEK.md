# Hide & Seek — Unspottable Style

A social deduction game where all players control identical characters and blend into
crowds of AI-driven lookalikes. One player is the **Seeker** and must identify and tag
real players among dozens of identical NPCs. The other players are **Hiders** who try to
act like AI to avoid detection.

- **Round Time:** 90 seconds
- **Seeker wins:** Tag all hiders
- **Hiders win:** At least one hider remains when time expires
- **Players:** 2-10

## Design Pillars

1. **Identical characters** — All players share the exact same model as the NPCs.
   No visual tells, no nametags, no outlines.
2. **AI-driven crowds** — NPCs follow believable patrol routes, idle animations, and
   environmental interactions. Hiders must mimic them perfectly.
3. **Environmental variety** — Multiple themed scenes (museum, office, library)
   each with unique crowd behaviors and hiding spots.
4. **Social tension** — The paranoia of being watched. The panic of breaking character.
   The satisfaction of a perfectly executed blend.

## VR Player - Seeker

The VR player is always the seeker and plays as a first-person in the themed scene.
He can walk through the crowd, observe behavior, and tag suspicious characters.

### Controls

| Action | Input |
|--------|-------|
| Move | Left thumbstick |
| Turn | Right thumbstick (snap) |
| Tag (point + trigger) | Trigger button |
| Scan (highlight recent movement) | Grip button |

### Tagging

Point at any character and press **Trigger**. Visually shoots a taser at the target

- **Correct tag:** The character is revealed as a hider and eliminated for the round.
- **Wrong tag:** All NPCs within 8 meters break patrol and run in random directions
  for 2 seconds at 1.5x walk speed, then resume their original patrol routes.
  the Seeker cannot tag again for **3s**.

**Design intent:** Tagging has a real penalty (cooldown + warning to hiders) so
spam-tagging is counterproductive. The Seeker must be deliberate.

### Scan (Grip)

Aim the controller in a direction and press **Grip** to fire a directional scan.
The scan marks positions where hiders have passed through in the last few seconds
and shows a rough direction they were heading. Only hiders within the scan cone
are detected.

- **What it reveals:** A brief footprint-style marker appears at each hider's
  position from ~3 seconds ago, plus a directional arrow indicating which way they
  were moving. NPCs are ignored.
- **Cone angle:** ~60° from the controller's pointing direction
- **Range:** ~10 meters
- **Cooldown:** 8s
- **Duration:** The marks persist for 2 seconds, then fade.
- **Purpose:** Give the Seeker a directional lead on hiders who recently moved,
  without revealing their exact current position or identity.

## Mobile Players (Hiders)

### Setup (10 seconds)

Scene loads with the full crowd visible. Each mobile player sees briefly their character
by a visual marker. The crowd begins its patrol routes. A short countdown plays, then
the round begins.

### Controls

Uses the generic gamepad controller layout

| Action | Input |
|--------|-------|
| Move | Left joystick |
| Interact (context action at locations) | Button A |

### Core Mechanics

- **Mimic the crowd:** Each scene has interactive locations (e.g., a desk to sit at,
  a painting to view, a shelf to browse). Walk near a location and press **Button A**
  to perform that location's action. The character plays the matching animation.
- **Movement is the primary tool:** Blend in by moving when NPCs move and stopping
  when they stop. NPCs follow fixed patrol routes — watch their patterns and repeat them.
- **Context actions:** Each interactive location has one action. When a hider is within
  2 meters of an interactive location, a subtle icon appears on their mobile screen
  (e.g., a hand icon). Pressing Button A then performs the action.

### Getting Caught

When tagged by the Seeker, the hider is eliminated:
- A brief elimination animation plays (character slumps / poofs)
- Eliminated hiders see the shared top-down screen. Their mobile controller inputs are disabled.

## Shared Screen (TV / Stream)

All hiders share a single screen that shows the whole map

| Element | Description |
|---------|-------------|
| **Scene camera** | Fixed top-down camera, shows the entire scene |
| **Timer** | 1:30 countdown |
| **Player list** | List of players and if they are still in the game |

## Environment Designs

Each scene features a crowd of identical characters. The environment is designed
to give both visual variety and tactical depth.

### 1. Museum Gallery

- **Setting:** Modern art museum with 4 connected galleries
- **NPCs:** 20 visitors, forming groups of 2-5 people
- **Patrol routes:** 3 predefined circuits — clockwise loop (visits galleries A→B→C→D→A),
  counter-clockwise loop (A→D→C→B→A), and center crossing (cuts through the atrium
  between galleries). Each NPC picks a route on spawn and follows it at a slow walk.
- **Interactive locations:**
  - **Paintings (4 per gallery):** Stand and look for 5s. NPCs stop at paintings
    along a predefined route. Hiders press **Button A** near a painting to look.
  - **Plaques (2 per gallery):** Read for 3s. Hiders press **Button A** near a plaque.

### 2. Office Open-Plan (future content)

- **Setting:** Cubicles, meeting rooms, break area, hallway
- **NPCs:** 30 workers
- **Patrol routes:** 5 predefined paths connecting desks → meeting rooms → break area →
  water cooler → supply closet. NPCs walk briskly between destinations, pause at
  each for 3–8s, then move to the next. Routes form overlapping loops to create
  natural traffic patterns.
- **Interactive locations:**
  - **Desks (12):** Sit and type (looping animation). Press **Button A** near an empty
    desk to sit. The character types until the player moves again.
  - **Water cooler (2):** Stand and drink (4s). Press **Button A** near the cooler.
  - **Meeting rooms (2):** Stand and gesture (6s). Press **Button A** inside.
  - **Break area (1):** Pour coffee (3s). Press **Button A** at the counter.

### 3. Library (future content)

- **Setting:** Multi-floor library with stacks, reading areas, stairs
- **NPCs:** 18 patrons (smaller crowd, quieter)
- **Patrol routes:** 4 circuits — floor 1 stacks (slow browsing), floor 2 stacks
  (slow browsing), reading area loop (enters, sits, reads, leaves), stair connections
  (between floors). NPCs spend 60% of time sitting and reading, 30% browsing shelves,
  10% walking between areas.
- **Interactive locations:**
  - **Reading tables (6):** Sit and read (10s+ loop). Press **Button A** near an
    empty chair. The character pulls out a book and reads. Long idle — easy to mimic
    but also easy to scan.
  - **Shelves (8 sections):** Browse (slow movement while facing shelf, 4s). Press
    **Button A** while near a shelf section. Character tilts head and runs a finger
    along book spines.
  - **Book return cart (2):** Return book (3s). Press **Button A** at the cart.

## Round Flow

1. **Setup (10s)** — Scene loads with crowd in motion. Hiders see their character
   confirmed. Seeker sees a black screen with "Prepare..."
2. **Hunt (90s)** — Seeker enters the scene. Hiders blend in. Seeker observes and tags.
3. **End** — Seeker wins (all hiders tagged) or Hiders win (time expires).

## Scoring

| Outcome | Points |
|---------|--------|
| Seeker tags a hider | +2 each |
| Seeker tags all hiders | +5 bonus |
| Hider survives the round | +3 |
| Hider is last survivor | +4 bonus |
| Seeker wrong-tags an NPC | -1 (to discourage spam) |

