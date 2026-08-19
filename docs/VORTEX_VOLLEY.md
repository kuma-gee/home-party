# Vortex Volley

Mobile players launch glowing orbs from the outer ring toward the center of a
circular arena. The VR player stands at the center and deflects incoming orbs back
outward with their hands. The VR player wins by surviving the full round timer or
eliminating all mobile players. Mobile players compete to be the last one standing.

- **VR Win:** Timer expires with mobile players alive, OR all mobile players eliminated
- **Mobile Win:** Last mobile player with lives remaining when round ends
- **Lives:** 3 per mobile player
- **Recommended Players:** 2–6 (1 VR + 1–5 mobile)
- **Round Style:** Fast asymmetric arena match
- **Round Duration:** 90 seconds

## Target Audience

Adults 18–35 at social gatherings. Mixed VR experience levels. Short 15–30 minute
play sessions with frequent player rotation. Players should be able to understand
the game within one round of watching.

## Design Pillars

1. **Simple party readability** — The entire game is visible in one circular arena:
   orbs, paddles, player zones, lives, and the VR defender at center.
2. **Asymmetric tension** — Mobile players choose when to attack but risk getting
   hit by their own reflected orb. The VR player reacts to pressure from all sides.
3. **Escalating chaos** — Orb speed increases with every successful VR block,
   making the arena progressively harder for everyone.
4. **Short rounds** — Three lives and a 90-second timer keep matches fast and
   easy to replay.
5. **Every player has stakes** — VR player has a clear win condition. Mobile players
   compete against each other AND the VR defender simultaneously.

## Player Experience

### VR Player (Defender)

You stand at the center of a glowing vortex. Orbs fly at you from all directions.
You swing your hands to block them, sending each one rocketing back where it came
from. Early on it's manageable — one orb at a time, plenty of time to react. Then
the tempo climbs. Two orbs. Three. You're spinning, reading trajectories, choosing
which threats to prioritize. The satisfaction comes from the physical rhythm: block,
block, redirect, block. When you survive a heavy barrage, you feel like a martial
arts master. When a fast orb slips past you, it's because you were overwhelmed, not
because the game cheated.

**Peak moment:** 60+ seconds in, 4–5 orbs active, you're barely keeping up, every
block is instinctive, the crowd is shouting.

### Mobile Player (Attacker)

You control a paddle on the outer ring. You tap to launch an orb at the VR defender.
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

The match takes place in a circular vortex arena.

| Element | Value |
|---------|-------|
| Arena radius | 4.5m |
| Wall height | 2.5m |
| Orb height | 0.9m (fixed) |
| Center platform radius | 1.2m |

Mobile player zones are evenly distributed around the outer ring. Each player owns
one fixed angular slice of the arena. Their paddle can slide left and right within
that slice, but cannot cross into another player's zone.

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
orbs. Every blocked orb is reflected back toward the outer ring. The VR player's
goal is to survive the full 90-second timer while eliminating as many mobile
players as possible through strategic reflections.

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

### VR Win Conditions

| Condition | Result |
|-----------|--------|
| Timer expires with ≥1 mobile player alive | VR wins (survived the siege) |
| All mobile players eliminated before timer | VR wins (total defense) |

### Center Hit (VR Miss)

If an orb reaches the center platform without being blocked:

1. The orb is destroyed on contact with the center floor.
2. No mobile player loses a life (the orb didn't reflect to any zone).
3. A replacement orb spawns at the launching mobile player's paddle once their
   orb supply is empty, after 1.5s.

The VR player is incentivized to block everything — missed orbs are wasted
elimination opportunities.

## Mobile Players — Attackers

Each mobile player controls one colored paddle on the outside of the arena. Their
goal is to launch orbs at the center, survive reflected returns, and outlast the
other mobile players.

### Controls

Uses the generic phone joystick layout.

| Action | Input |
|--------|-------|
| Move paddle left/right inside zone | Joystick horizontal axis |
| Launch orb | Tap anywhere on screen |

### Paddle Behavior

- Each paddle starts centered in its assigned zone.
- Paddle movement speed: **1.8 radians/second** (covers full zone width in ~1.0s).
- Paddle width: **1.3m**.
- Paddle travel is clamped to 80% of the player's zone half-arc, leaving gaps near
  zone borders.
- A paddle glows when an orb is ready to launch.
- A paddle flashes red when the player loses a life.

### Launching

- Each mobile player has an **orb supply**, starting with **1 orb**. Power-ups can
  add more orbs to the supply.
- Tapping launches one orb from the paddle's current position toward the center.
- Launch speed: **5.0m/s**.
- A player may have multiple orbs in flight at once (up to their supply).
- **Respawn:** When a player's supply is empty (all orbs resolved or destroyed), a
  new orb spawns at their paddle after **1.5s**.
- The orb travels in a straight line from paddle position to center platform.

### Orb Trajectories and Collision

When a mobile player launches an orb, it travels in a straight line from their
paddle position toward the center platform. If the VR player blocks it, the orb
reflects in the direction determined by the VR player's hand orientation and
continues across the arena.

**Reflected orbs can hit ANY mobile player in their path**, not just the launcher.

- If a reflected orb enters a mobile player's zone and their paddle is in the
  orb's path: that player loses 1 life, orb destroyed.
- If the paddle has moved out of the way: orb passes through the zone harmlessly
  and is destroyed when it reaches the arena wall.

**Design intent:** The VR player is a strategic pinball flipper. They choose where
reflected orbs go by aiming their blocks. Mobile players are at risk from:
1. Their own launched orbs being reflected back at them
2. Other players' orbs being redirected into their zone by the VR defender

This creates cross-player tension and emergent betrayal moments. A skilled VR
player can target specific mobile players by timing and aiming their blocks.

## Power-Ups

Power-ups float in the arena and are picked up by **mobile players only**, by
hitting them with an orb. An orb that collides with a power-up is destroyed, and
the power-up activates for that orb's owner (the mobile player who launched it).

**Tradeoff:** Orbs spent grabbing power-ups do not attack the VR defender and count
against the player's orb supply. Grabbing a power-up sacrifices an attack for a
temporary advantage.

### Pickup Mechanics

- Power-ups float on the orb plane (0.9m height) inside the arena, between the
  center platform and the outer ring.
- A mobile player picks up a power-up by launching an orb that collides with it.
- The colliding orb is destroyed on impact; the power-up activates immediately for
  that player.
- Power-ups despawn after a set lifetime if not picked up.

### Power-Up Types

| Power-up | Effect | Duration |
|----------|--------|----------|
| Extra Orb | +1 orb to supply | Instant |
| Turbo | +2.0m/s to all of the player's active orbs (capped at 10.0m/s) | Instant |
| Paddle Boost | Paddle movement speed ×1.5 | 10s |

### Spawning

- One power-up is active at a time.
- A new power-up spawns shortly after the previous one is picked up or expires.
- The spawn position is telegraphed briefly before the power-up activates, so
  players can aim their next orb.

**Design intent:** Power-ups give mobile players a second decision layer beyond
launch-and-dodge. Do you spend an orb attacking the VR defender, or divert it to
grab a power-up? The cost (losing an attack and one orb from supply) keeps
power-ups from being free value.

## Orb Rules

| Value | Amount |
|-------|--------|
| Launch speed | 5.0m/s |
| Reflect speed | Incoming + 1.5m/s |
| Maximum orb speed | 10.0m/s |
| Speed increase per shield block | +0.5m/s to all active orbs |
| Orb supply per mobile player | 1 base (power-ups can add more) |
| Respawn delay after supply empty | 1.5s |

### Escalation

Every successful VR shield block increases the speed of ALL active orbs by
0.5m/s, up to the 10.0m/s cap. Saber slices do not escalate speed. This means:

- Early round: orbs are slow, easy to dodge, VR player comfortable.
- Mid round: orbs are noticeably faster, mobile players must dodge quicker.
- Late round: orbs are screaming across the arena, chaos, laughter, mistakes.

Speed resets to base (5.0m/s) only when a new round starts.

### Orb Lifecycle

1. **Ready:** Orb sits at mobile player's paddle, glowing. Player can launch.
   Multiple ready orbs are possible with an expanded supply.
2. **Incoming:** Orb travels toward center. VR player can block.
3. **Reflected:** VR blocked it. Orb travels back toward outer ring at increased speed.
4. **Resolved:** Orb either hits a paddle (life lost) or passes through zone (safe).
   Orb destroyed. When the player's supply is empty, the respawn timer starts.

If VR misses (orb hits center): orb destroyed, respawn timer starts.

## Round Flow

### 1. Prepare Phase (5 seconds)

- Mobile players sync into the match.
- Each player receives 3 lives and 1 orb in their supply.
- Zones are assigned evenly around the arena.
- **Mobile onboarding:** Phone screen shows zone color, paddle position, and
  "Swipe to move paddle — Tap to launch" instruction overlay.
- **VR onboarding:** VR headset shows "Block orbs with your hands — Reflect them
  back at players" with animated hand demonstration.
- Shared screen shows **Get Ready!** with player names and zone colors.
- Round auto-starts after 5 seconds.

### 2. Play Phase (90 seconds)

- Timer begins. All mobile players have orbs ready.
- Mobile players tap to launch orbs at the center.
- VR player blocks and reflects incoming orbs.
- Reflected orbs return to outer ring — players dodge or get hit.
- Orb speed escalates with each VR block.
- Lives are lost, players are eliminated.

### 3. Elimination

- A mobile player is eliminated when lives reach 0.
- Eliminated player's paddle disappears. All of their orbs are removed permanently.
- Eliminated players see "Eliminated" on phone and can watch on shared screen.
- Round continues until timer expires or all mobile players eliminated.

### 4. Game End

- **Timer expires:** VR wins. Mobile players ranked by elimination order.
- **All mobile eliminated:** VR wins. Leaderboard shows elimination order.
- Leaderboard displayed on shared screen for 10 seconds.

## Win Conditions

**VR Player wins if:**
- 90-second timer expires with ≥1 mobile player alive, OR
- All mobile players eliminated before timer

**Mobile Player wins if:**
- They are the last mobile player alive when round ends

**Tiebreaker (mobile):** Most lives remaining → longest survival time.

**Leaderboard:** Shows elimination order and winner.

## Shared Screen and HUD

The shared desktop view shows the 3D arena and a lightweight HUD.

| Element | Description |
|---------|-------------|
| Timer | Countdown from 90 seconds, prominent center-top |
| State label | Waiting, Get Ready, GO, or Round Over |
| Lives list | Player name + zone color + heart icons |
| Speed indicator | Orb speed bar, fills as escalation increases |
| Leaderboard | Shown after round ends (elimination order) |

Mobile phones show:

| Phase | Display |
|-------|---------|
| Prepare | Zone color, paddle preview, control instructions |
| Play | Joystick, launch button, lives remaining, "Orb Ready" / "Cooldown" state |
| Eliminated | "Eliminated" text, spectate prompt |
| Game End | Winner announcement, elimination order |

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
| Mobile auto-launch | Optional: orbs launch automatically on cooldown (for players with motor difficulty) |

## Handling Edge Cases

### VR Player Inactivity

If no VR block occurs for 8 seconds:

- Shared screen shows "VR Player — Block the orbs!" prompt.
- After 12 seconds of inactivity: orbs auto-destroy on center hit (no reflects
  happen). Mobile players effectively play free-for-all with no risk.

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
