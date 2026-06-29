# Vortex Volley

Mobile players defend sections of a circular arena with moving deflector paddles
while the VR player stands near the center and bats a glowing orb back toward the
outer ring. Each missed return costs the defending mobile player a life. The last
mobile player with lives remaining wins.

- **Win Condition:** Last mobile deflector alive
- **Lives:** 3 per mobile player
- **Recommended Players:** 2–6
- **Round Style:** Fast elimination arena match
- **Round Duration:** 3 min

## Design Pillars

1. **Simple party readability** — The entire game is visible in one circular arena:
   orb, paddles, player zones, and lives.
2. **Asymmetric pressure** — Mobile players defend fixed slices of the arena while
   the VR player acts as the chaotic center striker.
3. **Escalating tempo** — Each successful paddle bounce increases orb speed until
   the arena becomes harder to defend.
4. **Short rounds** — Three lives and quick re-serves keep matches fast and easy
   to replay.

## Arena

The match takes place in a circular vortex arena.

| Element | Value |
|---------|-------|
| Arena radius | 4.5m |
| Wall height | 2.5m |
| Orb height | 0.9m |
| Center platform radius | 0.85m |

Mobile player zones are evenly distributed around the outer ring. Each player owns
one fixed angular slice of the arena. Their paddle can slide left and right within
that slice, but cannot cross into another player's zone.

## VR Player - Striker

The VR player stands inside the arena and uses their hands to either hit the orb
directly or grab and throw it. They are not trying to protect a personal goal;
their role is to keep the volley moving and send pressure toward the mobile
defenders.

### Controls

| Action | Input |
|--------|-------|
| Move | Left controller thumbstick |
| Strike orb | Swing either hand into the orb |
| Grab orb | Grip while hand is close to the orb |
| Throw orb | Release after a throwing motion |

### Striking and Throwing

When either VR hand passes close enough to the orb during a swing, the orb is sent
in the horizontal direction of that hand movement. The VR player may also grab any
idle or nearby orb and release it with a throwing motion to launch it.

- **Hit radius:** 0.3m
- **Minimum swing speed:** 0.5m/s
- **Minimum throw speed:** 0.5m/s
- **Launch speed:** 7.0m/s direction impulse, normalized to current orb speed by the game
- **Hit cooldown:** 0.3s

**Design intent:** The VR interaction should feel like batting a floating energy
ball rather than holding a racket. Direction comes from the hand's horizontal swing
or throw, so broad, readable gestures are rewarded. Grabbing gives the VR player a
second readable option when the arena is filling with multiple balls.

## Mobile Players - Deflectors

Each mobile player controls one colored paddle on the outside of the arena. Their
goal is to protect their own zone and outlast the other defenders.

### Controls

Uses the generic phone joystick layout.

| Action | Input |
|--------|-------|
| Move paddle left/right inside zone | Left joystick horizontal axis |

Only horizontal joystick movement matters. The paddle remains locked to its arena
slice and moves along the circumference.

### Paddle Behavior

- Each paddle starts centered in its assigned zone.
- Paddle movement speed is **2.0 angular units per second**.
- Paddle width is approximately **1.3m**.
- Paddle travel is clamped to 60% of the player's zone half-arc, leaving gaps near
  zone borders.
- A paddle flashes when it successfully deflects the orb.

## Orb Rules

Orbs spawn at the center of the arena at a constant height. A newly spawned orb is
idle until the VR player launches it by striking or throwing it. Once launched, it
travels horizontally and bounces when it reaches the outer ring and intersects an
active paddle.

| Value | Amount |
|-------|--------|
| Starting speed | 4.5m/s |
| Maximum speed | 9.0m/s |
| Speed increase | +0.3m/s per successful paddle bounce or score event |
| Starting active orb count | 1 |
| Maximum active orb count | Equal to the number of mobile players in the round |
| Respawn delay after score | 1.5s |

### Multi-Orb Escalation

- The round starts with **1** orb in the center for the VR player to launch.
- Each time an orb scores on a defender, the orb is removed as normal.
- After the respawn delay, the game refills center-spawned orbs up to the current
  target count.
- The target active orb count increases by **1** after each score event until it
  reaches the mobile-player cap.

### Bounce

If the orb reaches the outer ring where a living player's paddle is currently
covering the impact angle:

1. The orb bounces back into the arena.
2. The orb speed increases by 0.3m/s, up to the 9.0m/s maximum.
3. All launched orbs are normalized to the new shared speed.
4. The paddle flashes to confirm the save.

### Miss

If the orb reaches the outer ring inside a player's base zone and no paddle covers
the impact angle:

1. That player loses 1 life.
2. The orb is removed.
3. If more than one player is still alive, center-spawned replacement orbs appear
   after 1.5 seconds until the target active orb count is restored.
4. The target active orb count increases by 1, up to the player-count-based max.
5. The orb speed increases by 0.3m/s for the next launched orbs, up to the 9.0m/s
   maximum.

Because player zones are assigned contiguously around the ring, every missed outer
wall hit belongs to one defending player.

## Round Flow

### 1. Prepare Phase

- Mobile players are synced into the match as deflectors.
- Each player receives 3 lives.
- Zones are assigned evenly around the arena.
- The HUD shows **Get Ready!**.
- The round auto-starts after 5 seconds.

### 2. Play Phase

- A glowing orb spawns at the center of the arena.
- The VR player can launch each center orb by hitting it or grabbing and throwing it.
- Mobile players defend their assigned zones.
- The VR player strikes or throws orbs from the center area.
- The orb count and orb speed escalate as saves and misses occur.

### 3. Elimination

- A player is eliminated when their lives reach 0.
- Eliminated paddles no longer block the orb.
- The round continues until only one player remains alive.

### 4. Game End

When one or zero mobile players remain alive, the round ends and the leaderboard is
shown.

## Scoring

Final score is based on remaining lives.

| Result | Score Data |
|--------|------------|
| Survived | `survived = true`, score equals remaining lives |
| Eliminated | `survived = false`, score equals 0 lives |

The winner is the surviving mobile player. If the round ends with no survivors,
the leaderboard still ranks by remaining lives.

## Shared Screen and HUD

The shared desktop view shows the 3D arena and a lightweight HUD.

| Element | Description |
|---------|-------------|
| State label | Waiting, Get Ready, GO, or Round Over |
| Lives list | Player name with heart icons for remaining lives |
| Leaderboard | Shown after the round ends |

Mobile phones remain controller-first. They receive basic phase and score messages,
but gameplay information is intended to be read from the shared screen.
