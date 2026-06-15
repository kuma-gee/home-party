# Hide & Seek

A prop hunt game where the VR player is "It" (the seeker) and mobile players hide
as objects in a themed room. The VR player physically rummages through the space
— grabbing, shaking, and inspecting props

- **Round Time:** 2 minutes
- **VR wins:** Find all hiders
- **Mobile wins:** At least one hider remains when time expires
- **Players:** 3–8

## Design Pillars

1. **Universal rules** — Everyone knows hide & seek. Zero explanation needed.
2. **VR physics as the star** — The joy is physically rummaging through the room.
3. **Short rounds** — 2-minute rounds keep the headset rotating.
4. **Social tension** — The silence, the giggles, the near-misses.

## VR Player (Seeker)

First-person in a themed room. Smooth locomotion (no teleport), snap-turn.

Physically interact with the props to find the hiders.
The hider cannot swap or distract while the VR player holds their prop.

### Tagging (Grab + Trigger)

Two-step process: **grip** to grab a prop, then **trigger** to tag.

- **Correct tag:** The prop bursts open with a celebration. Hider is revealed.
- **Wrong tag:** Drop the prop, **2s stun** (can't grab or tag).

Design intent: You must walk over, bend down, and pick something up before you
can call it out. No spam-tagging from across the room.

### Controls

| Action | Input |
|--------|-------|
| Move | Left thumbstick |
| Turn | Right thumbstick (snap) |
| Grab prop | Grip button |
| Tag held prop | Trigger (while gripping) |
| Release / throw | Release grip |

## Mobile Players (Hiders)

### Setup (10 seconds)

Shared screen shows a top-down room view. Each hider picks a prop hy holding the
button A which will then highlight the nearest object that the player will change 
into when released. They can still move around in case the object isn't the one
they want. When time expires, the hunt begins.

### Controls

| Action | Input | Cooldown |
|--------|-------|----------|
| Move around | Left joystick | None |
| Jump | Button A | None |
| Swap prop | Hold Button A | 20s |
| Distract | Button B | 10s |

- **Distract:** Emit a sound (creak, thud, sneeze) from your position. Heard
  directionally by VR player. You can't swap for 5s after.
- **Swap:** Change to another prop. Same as in the setup phase

## Shared Screen

| Element | Description |
|---------|-------------|
| **Room camera** | Fixed dramatic angle (doesn't follow VR player) |
| **VR Player** | VR player is visible |
| **Hider count** | "4 hiding" badge |
| **Timer** | 2:00 countdown |
| **Found feed** | List of found hiders |

## Room Design

**Prop requirements:** 0.3m–2m in size, clear resting position. At least 3
eligible props per hider. No transparent objects, no wall/ceiling fixtures.

| Category | Examples |
|----------|----------|
| Furniture | Chair, stool, floor lamp, ottoman, trash can |
| Decor | Potted plant, vase, sculpture, rolled rug |
| Objects | Stack of books, box, backpack, guitar, mannequin |
| Containers | Cabinet, drawer, chest, wardrobe, cooler |
| Novelty | Suit of armor, teddy bear, skeleton |

## Round Flow

1. **Setup (8s)** — Hiders pick props. VR player sees black screen.
2. **Hunt (2 min)** — VR player searches. Hiders use peek/swap/distract.
3. **End** — VR wins (all found) or Hiders win (time expires).

## Scoring

| Outcome | Points |
|---------|--------|
| VR finds a hider | +1 each |
| VR finds all hiders | +3 bonus |
| Hider survives the round | +3 |
| Hider is last survivor | +2 bonus |
| Hider distracts | +1 bonus |
