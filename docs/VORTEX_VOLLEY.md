# Vortex Volley

Mobile players launch glowing orbs from the outer wall toward the center of an
octagonal arena. The VR player stands at the center and deflects incoming orbs back
outward with their hands, protecting a vulnerable **core** at the center. Every orb
that slips past the VR player damages the core. The VR player wins by keeping the
core alive for the full round timer or by eliminating all mobile players. Mobile
players win by destroying the core before the timer runs out, and compete among
themselves to be the last one standing.

- **VR Win:** Core survives the timer, OR all mobile players eliminated
- **Mobile Win:** Core health reaches 0 before the timer runs out
- **Core Health:** See [Arena](#arena)
- **Lives:** 3 per mobile player
- **Recommended Players:** 2–6 (1 VR + 1–5 mobile)
- **Round Style:** Fast asymmetric arena match
- **Round Duration:** 3 minutes (180 seconds)

## Target Audience

Adults 18–35 at social gatherings. Mixed VR experience levels. Short 15–30 minute
play sessions with frequent player rotation. Players should be able to understand
the game within one round of watching.

## Design Pillars

1. **Simple party readability** — The entire game is visible in one octagonal arena:
   orbs, paddles, player zones, lives, the core, and the VR defender at center.
2. **Asymmetric tension** — Mobile players choose when to attack but risk getting
   hit by their own reflected orb. The VR player reacts to pressure from all sides.
3. **Escalating chaos** — Orb speed increases with every successful VR block,
   making the arena progressively harder for everyone.
4. **Short rounds** — Three lives and a 3-minute timer keep matches fast and
   easy to replay.
5. **Every player has stakes** — VR player has a clear win condition. Mobile players
   compete against each other AND the VR defender simultaneously.

## Player Experience

### VR Player (Defender)

You stand at the center of a glowing vortex, guarding the vulnerable core at your
feet. Orbs fly at you from all directions. You swing your hands to block them,
sending each one rocketing back where it came from. Early on it's manageable — one
orb at a time, plenty of time to react. Then the tempo climbs. Two orbs. Three.
You're spinning, reading trajectories, choosing which threats to prioritize. The
satisfaction comes from the physical rhythm: block, block, redirect, block. When
you survive a heavy barrage, you feel like a martial arts master. When a fast orb
slips past you and cracks the core, it's because you were overwhelmed, not because
the game cheated.

**Peak moment:** 60+ seconds in, 4–5 orbs active, you're barely keeping up, every
block is instinctive, the crowd is shouting.

### Mobile Player (Attacker)

You control a paddle on the outer wall. You press A/B to launch an orb at the center core.
Here's the catch: when the VR player blocks your orb, it reflects in whatever
direction they aimed — and it might come flying at YOU or at someone else. You
launch, then immediately slide your paddle to a safe position in case the orb comes
back your way. But you also watch the other players' orbs — the VR defender might
redirect THEIR attacks into YOUR zone. The tension is constant: every orb in the
arena is a potential threat. You watch the VR player's hands, trying to predict
where they'll aim their blocks. When the VR player reflects someone else's orb
directly at you and you barely dodge it, you shout. When you launch and the VR
player sends it at your rival, you feel like you set up the perfect play.

**Peak moment:** You launch, the VR player reflects it straight at the player who's
been dominating, that player loses a life, the crowd erupts.

## Arena

The match takes place in an **octagonal** vortex arena with eight equal sides.

| Element | Value |
|---------|-------|
| Arena shape | Regular octagon, 8 equal sides |
| Arena radius (apothem) | 4.5m to each side midpoint (vertices at ~4.87m) |
| Wall height | 2.5m |
| Orb height | 0.9m (fixed) |
| Center platform radius | 1.2m |
| Core (center object) | Sits on the center platform, protected by the VR player |
| Core health | 20 (MVP default — tune during playtesting) |

Each of the eight sides is a potential player slot. With fewer than eight mobile
players, empty slots are closed up and the players are distributed evenly around
the octagon so they face each other as directly as possible:

- **2 players** → opposite sides (180° apart)
- **3 players** → spread ~120° apart (sides 0, 3, 5)
- **4 players** → every other side (90° apart)
- **5–7 players** → spread as evenly as the 8 sides allow
- **8 players** → every side filled

Each player owns one side of the octagon. Their paddle slides along the wall
within that side and cannot cross into another player's zone.

## Orb Physics

Orbs exist on a fixed horizontal plane at 0.9m height. All movement and collision
is 2D (X/Z only). Vertical hand position during VR blocks is ignored — only
horizontal hand position and palm direction matter.

**Rationale:** 2D plane keeps collision readable for mobile players (paddle always
at same height as orb) and simplifies trajectory prediction. VR physicality comes
from arm swing direction, not vertical positioning. Party game clarity > physics
realism.

## VR Player — Defender

The VR player stands on the center platform and uses their hands to block incoming
orbs, protecting the core at the center. Every blocked orb is reflected back toward
the outer wall. The VR player's goal is to keep the core alive for the full
3-minute timer while eliminating as many mobile players as possible through
strategic reflections.

### Controls

| Action | Input |
|--------|-------|
| Rotate body / face direction | Left controller thumbstick (or physical rotation) |
| Block orb (shield) | Swing either hand, open palm, into the orb's path |
| Slice orb (saber) | Hold grip/trigger + swing hand into the orb's path |
| Aim reflect | Orient palm horizontally at moment of impact |

### Blocking and Reflecting

When either VR hand passes through an orb's trajectory, the orb is reflected. The
reflect direction is determined by the horizontal direction the palm is facing at
the moment of impact (vertical hand angle is ignored — see Orb Physics).

- **Block radius:** 0.35m around each hand (horizontal distance only)
- **Minimum block speed:** 0.3m/s (prevents static hand parking)
- **Reflect speed:** Incoming speed + 1.5m/s, capped at 10.0m/s
- **Block cooldown:** 0.2s per hand
- **Reflect angle:** Based on palm's horizontal facing direction at impact

### Feedback

| Event | Visual | Audio | Haptic |
|-------|--------|-------|--------|
| Successful block | Orb flash + hand trail burst | Sharp impact crack | Short pulse (0.1s) |
| Missed orb (hits center) | Red pulse on arena floor | Low thud | Long rumble (0.3s) |
| Player eliminated | Zone shatters visually | Glass break sound | Double pulse |
| Orb sliced | Orb splits with spark burst | Quick slice whoosh | Sharp pulse (0.1s) |

**Design intent:** Blocking should feel like slapping a heavy ball with an open
palm. The physical gesture is broad and readable. Reflect direction requires aim —
skilled VR players can target specific mobile player zones. The minimum block speed
prevents holding hands still and waiting; the VR player must actively swing.

### Saber (Slice)

The VR player has a second tool: the saber. Unlike the shield (which reflects at
increased speed), the saber **slices an orb into two** without changing its speed.

| Tool | Hand state | Effect on orb |
|------|-----------|---------------|
| Shield | Open palm | Reflect at incoming + 1.5m/s; triggers +0.5m/s escalation |
| Saber | Grip/trigger held | Split into two at current speed; no escalation |

**Saber slice rules:**

- Slicing an orb splits it into two orbs, both at the orb's current speed (no
  halving, no reflect boost).
- The two orbs diverge at ±20° from the slice direction.
- Split orbs can hit **any** mobile player in their path, not just the original
  launcher.
- Slicing does **not** trigger the +0.5m/s speed escalation — only shield blocks do.
- Slice cooldown: 0.3s per hand (same minimum swing speed as blocking).

**Design intent:** The shield is the "speed" tool — it reflects fast and escalates
the whole arena. The saber is the "spread" tool — it turns one orb into two threats
without making anything faster. Choosing between them is the VR player's core
decision: concentrate pressure (reflect) or multiply it (slice). Slicing late in a
round floods the arena with orbs without pushing the speed cap higher, creating a
different kind of pressure than escalating speed.

### Win Conditions

| Condition | Result |
|-----------|--------|
| Timer expires with the core alive | VR wins (survived the siege) |
| All mobile players eliminated before timer | VR wins (total defense) |
| Core health reaches 0 | Mobile players win (core destroyed) |

### Center Hit (Core Damage)

If an orb reaches the center platform without being blocked:

1. The core loses 1 health on contact.
2. The orb **bounces off the core and continues** at its current speed. It is not
   destroyed and no replacement orb is generated.
3. A per-orb **0.3s damage cooldown** prevents repeated damage while an orb
   grazes the core.
4. No mobile player loses a life (the orb didn't exit through any zone).

When the core's health reaches 0, the mobile players win immediately.

The VR player is incentivized to block everything — every missed orb chips away at
the core repeatedly as it bounces around the arena, and a destroyed core ends the
round.

## Mobile Players — Attackers

Each mobile player controls one colored paddle on the outside of the arena. Their
goal is to launch orbs at the center, survive reflected returns, and outlast the
other mobile players.

### Controls

Uses the generic phone joystick layout. The phone is controller-only — no game
info is shown on it; all state is displayed on the shared desktop screen.

| Action | Input |
|--------|-------|
| Move paddle along side | Joystick direction (projected onto the player's side) |
| Launch orb | Press A or B button |
| Aim launch | Paddle movement at the moment of launch (see [Launching](#launching)) |

### Paddle Behavior

- Each paddle starts centered on its assigned side.
- Joystick direction is interpreted in shared-screen space and projected onto
  the player's side tangent, so the paddle moves in the direction the player
  pushes as they see it.
- Paddle movement speed: **1.8 radians/second** around the center (moves the
  paddle along its side).
- Paddle width: **1.3m**.
- Paddle travel is clamped to 80% of the side's half-length, leaving gaps near
  the octagon corners.
- A paddle glows when an orb is ready to launch.
- A paddle flashes red when the player loses a life.

### Launching

- Each mobile player **always has exactly one orb ready on their paddle**. There is
  no orb supply or ammo count.
- Pressing A or B launches the ready orb from the paddle's current position.
- Launch speed: **5.0m/s**.
- **Aim:** the launch direction is based on paddle movement at the moment of launch.
  A stationary paddle fires straight at the center; a moving paddle fires up to
  **30°** toward its direction of travel.
- The orb travels in a straight line from paddle position toward the center platform.
- When the orb leaves the arena (see [Orb Trajectories and Collision](#orb-trajectories-and-collision)),
  a new ready orb appears on the launching player's paddle after **1.5s**. An orb
  is **never** consumed by hitting the core, a paddle, a wall, or a power-up.
- Power-ups can create additional orbs directly in play. Those orbs are independent
  of the paddle orb and never respawn once lost.

### Orb Trajectories and Collision

When a mobile player launches an orb, it travels in a straight line from their
paddle position toward the center platform. If the VR player blocks it, the orb
reflects in the direction determined by the VR player's hand orientation and
continues across the arena.

Orbs behave like Pong balls: they **bounce and keep playing** on every contact
except one.

| Contact | Result |
|---------|--------|
| Core | Core loses 1 health (0.3s per-orb damage cooldown), orb bounces off and continues |
| Mobile paddle | Orb bounces off and continues |
| Arena wall | Orb bounces and continues |
| Power-up | Pickup activates, orb continues |
| VR shield | Orb reflects, continues |
| Player area (missed paddle) | Orb is lost — see below |

**Reflected orbs can threaten ANY mobile player**, not just the launcher.

- A player loses **1 life** only when an orb **exits the arena through their
  player area** — i.e. it got past their paddle and out of bounds.
- That orb is then destroyed. A new ready orb returns to the **launching**
  player's paddle after 1.5s, regardless of whose area it exited. Ownership never
  transfers.
- Hitting a paddle or exiting any other way does not end the orb.

**Design intent:** The VR player is a strategic pinball flipper. They choose where
reflected orbs go by aiming their blocks. Mobile players are at risk from:
1. Their own launched orbs being reflected back at them
2. Other players' orbs being redirected into their zone by the VR defender

This creates cross-player tension and emergent betrayal moments. A skilled VR
player can target specific mobile players by timing and aiming their blocks.

## Power-Ups

Power-ups float in the arena and are picked up by **mobile players only**, by
hitting them with an orb. An orb that collides with a power-up **keeps flying** and
the power-up activates for that orb's owner (the mobile player who launched it).

**Tradeoff:** Grabbing a power-up consumes neither the orb nor the player's ready
orb, but diverting a shot into a power-up means it is not aimed at the core, and the
orb stays live for the VR player to block or for another player to dodge.

### Pickup Mechanics

- Power-ups float on the orb plane (0.9m height) inside the arena, between the
  center platform and the outer wall.
- A mobile player picks up a power-up when any orb they own collides with it.
- The colliding orb is **not** destroyed; the power-up activates immediately for
  that orb's owner.
- Power-ups despawn after a set lifetime if not picked up.

### Power-Up Types

| Power-up | Effect | Duration |
|----------|--------|----------|
| Duplicate | Splits the orb that picked it up into two in place; both continue at the current speed, with the clone diverging **20°** | Instant |
| Turbo | +2.0m/s to all of the player's active orbs (capped at 10.0m/s) | Instant |
| Paddle Boost | Paddle movement speed ×1.5 | 10s |

Duplicate creates a normal in-play orb owned by the launcher. It can score core
damage, be reflected, and hit players like any other orb. If it leaves the arena,
it is gone permanently — it does not return to the paddle.

### Spawning

- One power-up is active at a time.
- A new power-up spawns shortly after the previous one is picked up or expires.
- The spawn position is telegraphed briefly before the power-up activates, so
  players can aim their next orb.

**Design intent:** Power-ups give mobile players a second decision layer beyond
launch-and-dodge. Do you aim at the VR defender, or steer your shot through a
power-up and multiply or accelerate the orbs already in play? The cost is
positioning and risk — the orb stays live and can be blocked or lost.

## Orb Rules

| Value | Amount |
|-------|--------|
| Launch speed | 5.0m/s |
| Reflect speed | Incoming + 1.5m/s |
| Maximum orb speed | 10.0m/s |
| Speed increase per shield block | +0.5m/s to all active orbs |
| Ready orb per mobile player | 1 (always, while alive) |
| Respawn delay after orb leaves arena | 1.5s |
| Core damage cooldown per orb | 0.3s |

### Escalation

Every successful VR shield block increases the speed of ALL active orbs by
0.5m/s, up to the 10.0m/s cap. Saber slices do not escalate speed. This means:

- Early round: orbs are slow, easy to dodge, VR player comfortable.
- Mid round: orbs are noticeably faster, mobile players must dodge quicker.
- Late round: orbs are screaming across the arena, chaos, laughter, mistakes.

Speed resets to base (5.0m/s) only when a new round starts.

### Orb Lifecycle

1. **Ready:** One orb sits at the mobile player's paddle, glowing. Player can launch.
   Exactly one ready orb exists per living mobile player.
2. **Incoming:** Orb travels toward center. VR player can block.
3. **Reflected:** VR blocked it. Orb travels back toward the outer wall at
   increased speed.
4. **Bouncing:** Orb stays alive through core hits, paddle hits, wall bounces, and
   power-up pickups. Only leaving the arena ends it.
5. **Lost:** Orb exits through a player area. That area's player loses 1 life; the
   orb is destroyed and a new ready orb returns to the **launcher's** paddle after
   1.5s.

Hitting the core does **not** destroy the orb — it deals 1 damage and bounces off.
Power-ups created by Duplicate are separate in-play orbs; they are lost permanently
and never return to a paddle.

## Round Flow

### 1. Prepare Phase

- Mobile players sync into the match.
- Each player receives 3 lives and one ready orb on their paddle.
- Zones are assigned evenly around the arena.
- **Mobile onboarding:** The phone shows only the joystick and A/B buttons.
  Control instructions ("Swipe to move paddle — press A/B to launch") are shown
  on the shared desktop screen. Pressing A/B readies the player.
- **VR onboarding:** VR headset shows "Block orbs with your hands — Reflect them
  back at players" with animated hand demonstration.
- Shared screen shows **Get Ready!** with player names and zone colors.
- The round starts once **every mobile player and the VR player are ready**.
  Mobile players ready up with A/B on their phone; the VR player readies from
  the VR prepare HUD.

### 2. Play Phase (3 minutes)

- Timer begins. All mobile players have orbs ready.
- Mobile players press A/B to launch orbs at the center.
- VR player blocks and reflects incoming orbs.
- Reflected orbs return to outer wall — players dodge or get hit.
- Orb speed escalates with each VR block.
- Lives are lost, players are eliminated.

### 3. Elimination

- A mobile player is eliminated when lives reach 0.
- Eliminated player's paddle disappears. All of their orbs are removed permanently.
- Eliminated players' phones show only the joystick and buttons (no launch
  input); they watch the rest of the match on the shared screen.
- Round continues until timer expires or all mobile players eliminated.

### 4. Game End

- **Timer expires (core alive):** VR wins. Mobile players ranked by elimination order.
- **All mobile eliminated:** VR wins. Leaderboard shows elimination order.
- **Core destroyed:** Mobile players win. Leaderboard shows elimination order.
- Leaderboard displayed on shared screen for 10 seconds.

## Win Conditions

**VR Player wins if:**
- The core survives the full 3-minute timer, OR
- All mobile players are eliminated before the timer

**Mobile Players win if:**
- The core's health reaches 0 before the timer runs out

**Individual mobile ranking:** Determined by elimination order — the last mobile
player standing ranks highest.

**Tiebreaker (mobile):** Most lives remaining → longest survival time.

**Leaderboard:** Shows the winning side, elimination order, and (for mobile wins)
damage dealt.

## Shared Screen and HUD

The shared desktop view shows the 3D arena and a lightweight HUD.

| Element | Description |
|---------|-------------|
| Timer | Countdown from 3 minutes, prominent center-top |
| Core health | Bar showing the core's remaining health |
| State label | Waiting, Get Ready, GO, or Round Over |
| Lives list | Player name + zone color + heart icons |
| Speed indicator | Orb speed bar, fills as escalation increases |
| Leaderboard | Shown after round ends (elimination order) |

Mobile phones are controller-only across all phases: the joystick moves the
paddle and the A/B buttons launch. No game state, lives, or scores are shown on
the phone — all of that is displayed on the shared desktop screen.

## Presentation

### Visual Escalation

| Orb Speed | Visual State |
|-----------|-------------|
| 5.0–6.5m/s | Soft glow, short trail |
| 6.5–8.0m/s | Bright glow, long trail, slight screen shake on VR block |
| 8.0–10.0m/s | Intense glow, particle trail, arena edge pulse on block |

### Audio Layers

- **Base:** Ambient vortex hum, constant.
- **Per orb:** Whoosh on launch, impact crack on VR block, shatter on life lost.
- **Escalation:** Background music tempo increases with orb speed. At 8.0m/s+,
  bass layer added.
- **Crowd reactive:** Cheers on elimination, gasps on close dodges, roar at 60+
  seconds if 3+ players still alive.

## Accessibility

| Option | Description |
|--------|-------------|
| Colorblind modes | Deuteranopia, protanopia, tritanopia zone color palettes |
| One-handed VR | Single-hand block mode (larger hit radius, slower orbs) |
| Reduced motion | Disable screen shake, reduce particle intensity |

## Handling Edge Cases

### VR Player Inactivity

If no VR block occurs for 8 seconds:

- Shared screen shows "VR Player — Block the orbs!" prompt.
- After 12 seconds of inactivity: orbs that reach the core are destroyed instead of
  bouncing (no reflects happen). Mobile players effectively play free-for-all with
  no risk.

This prevents griefing where VR player refuses to engage.

### 2-Player Configuration (1 VR + 1 Mobile)

- Mobile player gets 5 lives instead of 3.
- Round timer reduced to 60 seconds.
- Orb speed escalation reduced to +0.3m/s per block.
- Playable but less chaotic — recommended minimum is 3 mobile players.

### All Mobile Players Eliminated Early

If all mobile players eliminated before 60 seconds:

- "Quick Rematch" option appears on shared screen.
- New round starts immediately with same players, fresh lives.
