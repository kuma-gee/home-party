# Vortex Volley

Mobile players launch orbs from the outer wall toward the center of an octagonal
arena. The VR player stands at the center, using a **shield** to reflect orbs and a
**saber** to split them, protecting a vulnerable **core**. Orbs that get past the VR
player damage the core.

| | |
|---|---|
| **Players** | 2–6 recommended (1 VR + 1–5 mobile); arena supports up to 8 |
| **Round duration** | 3 minutes (180 seconds) |
| **Mobile lives** | 3 each |
| **VR win** | Core survives the timer, OR all mobile players are eliminated |
| **Mobile win** | Core health reaches 0 before the timer expires |

## Target Audience

Adults 18–35 at social gatherings. Mixed VR experience levels. Short 15–30 minute
sessions with frequent player rotation. Players should understand the game within
one round of watching.

## Design Pillars

1. **Simple party readability** — The whole game is visible in one octagonal arena:
   orbs, paddles, player zones, lives, the core, and the VR defender at center.
2. **Asymmetric tension** — Mobile players choose when to attack but risk getting
   hit by their own reflected orb. The VR player reacts to pressure from all sides.
3. **Burst chaos** — Active shield blocks **overcharge** the reflected orb with a
   temporary speed boost, creating intense but contained moments of danger. The
   boost expires when the orb hits something, so skilled VR players create more
   spikes of chaos without permanently overwhelming the arena.

## Arena

An **octagonal** vortex arena with eight equal sides.

| Element | Value |
|---------|-------|
| Arena shape | Regular octagon, 8 equal sides |
| Wall height | 2.5m |
| Orb height | 1.3m (fixed) |
| Center platform radius | 1.2m |
| Core | Sits on the center platform, protected by the VR player |
| Core health | 20 (MVP default — tune during playtesting) |

The arena has eight mobile-player slots. With fewer players, empty slots stay closed
and the remaining players are spread evenly so they face each other as directly as
possible:

- **2 mobile players** → opposite sides (180° apart)
- **3 mobile players** → ~120° apart (sides 0, 3, 5)
- **4 mobile players** → every other side (90° apart)
- **5–7 mobile players** → spread as evenly as the 8 sides allow
- **8 mobile players** → every side filled

Each mobile player owns one side. Their paddle slides along the wall within that
side and cannot enter another player's zone.

## Orb Plane

Orbs stay on a fixed horizontal plane at 1.3m. All movement and collision is 2D
(X/Z only). Vertical shield position during VR blocks is ignored — only the
shield's horizontal position and facing direction matter.

**Rationale:** A 2D plane keeps collision readable for mobile players (paddle always
at orb height) and simplifies trajectory prediction. VR physicality comes from
swinging and angling the shield, not vertical positioning. Party game clarity >
physics realism.

## VR Player — Defender

The VR player stands on the center platform holding a **shield** in the left hand
and a **saber** in the right. The shield reflects incoming orbs; the saber slices
them in two. Tools can be swapped in settings for left-handed players.

### Controls

| Action | Input |
|--------|-------|
| Rotate body / face direction | Left controller thumbstick (or physical rotation) |
| Block orb (shield) | Swing the shield into the orb's path |
| Slice orb (saber) | Swing the saber into the orb's path |
| Aim reflect | Face the shield's front toward the target at moment of impact |

### Shield — Block and Reflect

When the shield crosses an orb's trajectory, the orb is **always reflected** in the
direction the shield's front face points at impact — no minimum speed required.

- **Block radius:** 0.35m around the shield's blocking surface (horizontal only)
- **Reflect speed:** Unchanged at current speed on any block (active or passive)
- **Reflect Boost:** Active blocks (shield moving ≥0.3m/s at impact) apply a
  **temporary +2.0m/s boost** to the reflected orb (see Reflect Boost below)
- **Block cooldown:** 0.2s per shield
- **Reflect angle:** Shield's horizontal facing direction at impact

An **active block** — shield moving at or above 0.3m/s at impact — reflects at
current speed and applies a **Reflect Boost** to the orb. A **passive block** —
shield held still or moving slower — still reflects at current speed with no boost.
This prevents parking the shield in one spot to farm boosts.

**Design intent:** Blocking should feel like driving a heavy shield into a fast ball.
The gesture is broad and readable, but reflect direction requires aim, letting
skilled VR players target specific mobile zones. An active swing doesn't add permanent
speed — instead, it **overcharges** the orb with a temporary boost that expires on
contact, creating a burst of danger rather than a permanent escalation.

### Saber — Slice

The saber **splits an orb into two** without changing its speed, and each slice
removes **1 orb health**. Any contact with the saber cuts the orb — no minimum
swing speed required.

- Orbs start with **2 health**; every slice reduces both resulting halves by 1.
  An orb splits once, then the next slice destroys it.
- Both orbs continue at the orb's current speed (no halving, no speed change).
- If the sliced orb had a **Reflect Boost**, both halves **inherit the boost** —
  slicing a fast orb creates two fast orbs.
- The two orbs diverge ±20° from the orb's velocity vector.
- Split orbs can hit **any** mobile player in their path, not just the launcher.
- Slicing does **not** apply a Reflect Boost — only active shield blocks do.
- An orb shrinks one step after each slice. At **0 health** it is destroyed instead
  of splitting again.
- **Slice cooldown:** 0.3s per saber.

**Design intent:** The shield is the "speed" tool and the saber is the "spread"
tool. Choosing between them is the VR player's core decision: overcharge an orb
with a temporary boost (reflect) or multiply it (slice). Slicing a boosted orb
creates two fast orbs — a delicious risk/reward: do you slice the glowing orb and
multiply the threat, or let it bounce and lose the boost? Repeated slices flood
the arena with smaller, weaker orbs until the family is worn down and destroyed.

### Feedback

| Event | Visual | Audio |
|-------|--------|-------|
| Successful block | Orb flash + shield trail burst | Sharp impact crack |
| Reflect Boost applied | Orb ignites white-hot, afterimage trail appears | Rising pitch sweep |
| Reflect Boost expires | Afterimage fades, glow returns to normal | Descending tone |
| Missed orb (hits center) | Red pulse on arena floor | Low thud |
| Player eliminated | Zone shatters visually | Glass break sound |
| Orb sliced | Orb shrinks and splits with spark burst | Quick slice whoosh |

### Core Damage

If an orb reaches the center platform without being blocked:

1. The core loses 1 health on contact.
2. The orb is destroyed.

At 0 core health, the mobile players win immediately. The VR player is incentivized
to block everything: each missed orb chips the core and forces the attacker to wait
for a replacement orb.

## Mobile Players — Attackers

Each mobile player controls one colored paddle on the outside of the arena. Their
goal is to launch orbs at the center, survive reflected returns, and outlast the
other mobile players.

### Controls

Uses the generic phone joystick layout. The phone is controller-only — all game
state is displayed on the shared desktop screen.

| Action | Input |
|--------|-------|
| Move paddle along side | Joystick direction (projected onto the player's side) |
| Launch orb | Press A or B |
| Aim launch | Paddle movement at the moment of launch (see Launching) |

### Paddle

- Starts centered on its assigned side.
- Joystick direction is interpreted in shared-screen space and projected onto the
  player's side tangent, so the paddle moves in the direction the player pushes as
  they see it.
- Movement speed: **1.8m/s** along the side.
- Travel is clamped to ±80% of the side's half-length from its center, leaving gaps
  near the octagon corners.
- Shows the ready orb hovering just in front of it, toward the arena center, while
  the player can launch. The orb follows the paddle as it moves.
- Glows when an orb is ready to launch.
- Flashes red when the player loses a life.

### Launching

- Each mobile player **always has exactly one ready orb** hovering in front of their
  paddle. There is no orb supply or ammo count. The ready orb is visual only until
  launched: it cannot hit the core, paddles, or players.
- Pressing A or B launches the ready orb from its current position at **5.0m/s**
  (always base speed — boosts do not carry over to new orbs).
- A stationary paddle fires straight at the center. A moving paddle fires up to
  **30°** toward its direction of travel.
- The orb travels in a straight line from the paddle toward the center platform.
- When the orb leaves the arena, a new ready orb appears on the launching player's
  paddle after **1.5s**. Ownership never transfers.

## Orbs

### Rules

| Value | Amount |
|-------|--------|
| Launch speed | 5.0m/s (always — boosts do not carry over to new orbs) |
| Reflect speed | Unchanged on any block (active or passive) |
| Reflect Boost (active block) | +2.0m/s temporary; expires on contact with wall, paddle, core, or saber |
| Maximum orb speed | 10.0m/s (12.0m/s while boosted by Reflect Boost or Turbo) |
| Minimum shield swing speed for Reflect Boost | 0.3m/s |
| Orb health | 2 |
| Health removed per saber slice | 1 |
| Ready orb per mobile player | 1 (always, while alive) |
| Respawn delay after orb leaves arena | 1.5s |
| Orb ownership | Never transfers — always the mobile player who launched it |

### Collision and Life Loss

Orbs behave like Pong balls: they **bounce and keep playing** on every contact
except leaving through a player area. **Orbs do not collide with each other** —
they pass through one another.

| Contact | Result |
|---------|--------|
| Core | Core loses 1 health; orb is destroyed (boost irrelevant) |
| Mobile paddle | Orb bounces at **normal speed** (boost removed if active) |
| Arena wall | Orb bounces at **normal speed** (boost removed if active) |
| Power-up | Pickup activates; orb continues (boost unchanged) |
| VR shield | Orb reflects at current speed; active block applies Reflect Boost |
| VR saber | Orb loses 1 health; splits and continues if health remains (both halves keep any active boost) |
| Player area (missed paddle) | Orb is lost — see below |

**Reflected orbs can threaten ANY mobile player**, not just the launcher. A player
loses **1 life** only when an orb **exits the arena through their player area** —
the full width of their assigned side behind the paddle. That orb is then destroyed
and the launcher gets a replacement (see Launching).

**Design intent:** The VR player is a strategic pinball flipper. Mobiles are at risk
from their own reflected orbs and from other players' orbs redirected into their
zone, creating cross-player tension and emergent betrayal moments.

### Reflect Boost

An **active shield block** (shield moving ≥0.3m/s at impact) applies a **Reflect
Boost** to the reflected orb: **+2.0m/s temporary speed**, up to the 12.0m/s cap.
The boost is **visual and immediate** — the orb glows intensely with an afterimage
trail, making it instantly readable as dangerous.

**The boost expires when the orb hits something:**

| Event | Result |
|-------|--------|
| Hits arena wall | Bounces at normal speed (boost removed) |
| Hits mobile paddle | Bounces at normal speed (boost removed) |
| Hits core | Orb destroyed (boost irrelevant) |
| Is sliced by saber | Both halves **keep the boost** |
| Exits through player area | Orb destroyed (boost irrelevant) |

**Key properties:**

- **Temporary, not permanent** — The boost doesn't accumulate. A new orb always
  launches at 5.0m/s, and a boosted orb returns to its pre-boost speed on contact.
- **No global escalation** — Only the reflected orb is boosted; other orbs in
  play are unaffected.
- **Passive blocks don't boost** — Shield held still or moving <0.3m/s reflects
  at current speed with no boost, preventing shield-parking to farm boosts.
- **Slicing multiplies the boost** — If a boosted orb is sliced, both halves
  inherit the boost, creating two fast orbs. This is a deliberate risk/reward:
  the VR player chooses whether to slice a glowing orb (multiply the threat) or
  let it bounce (lose the boost).
- **Boosts don't stack** — A boosted orb that is reflected again gets a fresh
  +2.0m/s boost (replacing, not adding to, the previous boost). The orb returns
  to its pre-boost speed before the new boost is applied.

**Design intent:** Reflect Boost creates **burst moments** of intense danger rather
than gradual escalation. A skilled VR player creates more glowing, screaming orbs,
but the chaos is always contained — each boost expires on contact. Mobile players
can see which orbs are dangerous (glowing, trailing) and know the threat is
temporary. This keeps the arena readable and prevents the "everything is too fast"
death spiral of permanent escalation.

- **Early round:** Orbs are slow, easy to dodge, VR player comfortable. Occasional
  boosts create excitement without overwhelming.
- **Mid round:** More boosted orbs in flight, mobile players must track which
  orbs are glowing and dodge accordingly.
- **Late round:** A skilled VR player can keep multiple orbs boosted simultaneously,
  creating a symphony of glowing, screaming orbs — chaos, laughter, mistakes.

### Lifecycle

1. **Ready:** One glowing orb hovers in front of the mobile player's paddle and
   follows it. It disappears when launched and is visual only — no collision or
   damage until it leaves the paddle. Exactly one exists per living mobile player.
2. **In play:** Orb travels, is reflected or sliced, bounces off paddles/walls,
   and can trigger power-ups. Only leaving the arena or hitting the core ends it.
3. **Lost:** Orb exits through a player area. That player loses 1 life; the orb is
   destroyed and the launcher's paddle gets a new ready orb after 1.5s.

Orbs created by Duplicate are separate in-play orbs. They can damage the core, be
reflected, and hit players, but are lost permanently if they leave the arena — they
never return to a paddle.

## Power-Ups

Power-ups add a second decision layer beyond launch-and-dodge. They are picked up by
**mobile players only** — hit one with an orb.

### Pickup Mechanics

- Float on the orb plane (1.3m) inside the arena, between the center platform and the
  outer wall.
- A mobile player picks one up when any orb they own collides with it.
- The orb keeps flying; the power-up activates immediately for its owner. Neither the
  orb nor the player's ready orb is consumed.
- Despawn after a set lifetime if not picked up.

### Types

| Power-up | Effect | Duration |
|----------|--------|----------|
| Duplicate | Splits the orb that picked it up into two in place; both continue at current speed, clone diverging **20°** from the orb's velocity vector | Instant |
| Turbo | +2.0m/s to the orb that picked it up only; can exceed the normal cap up to **12.0m/s**; does not stack. **Permanent** until the orb is lost (unlike Reflect Boost, which expires on contact). Visually distinct: golden shimmer, keeps orb color (see Visual States) | Instant |
| Paddle Boost | Paddle movement speed set to fixed boosted value (×1.5); does not stack — re-pickup refreshes the timer only | 10s |

### Spawning

- One power-up is active at a time.
- A new one spawns shortly after the previous one is picked up or expires.
- The spawn position is telegraphed briefly before activation, so players can aim
  their next orb.

**Design intent:** Do you aim at the VR defender, or steer through a power-up and
multiply or accelerate the orbs already in play? The cost is positioning and risk —
the diverted orb stays live and can be blocked or lost.

## Round Flow

### 1. Prepare Phase

- Mobile players sync into the match.
- Each mobile player receives 3 lives and one ready orb on their paddle.
- Zones are assigned around the arena.
- The shared screen shows **Get Ready!** with player names and zone colors.
- The round starts once **every mobile player and the VR player are ready**. Mobile
  players ready up with A/B; the VR player readies from the VR prepare HUD.

### 2. Play Phase (3 minutes)

- Timer begins. All living mobile players have orbs ready.
- Mobile players launch orbs at the center.
- The VR player blocks and reflects with the shield, and can slice with the saber.
- Active shield blocks apply a **Reflect Boost** — the reflected orb glows and
  screams across the arena until it hits something.
- Reflected orbs return to the outer wall — players dodge or lose lives.
- Boosted orbs are visually distinct (extreme glow, afterimage trail) so players
  can see which orbs are dangerous.

### 3. Elimination

- A mobile player is eliminated at 0 lives.
- Their paddle disappears and their in-flight orbs are destroyed immediately.
- Their phone shows only the joystick and buttons (no launch input); they watch the
  rest of the match on the shared screen.
- The round continues until the timer expires, the core is destroyed, or all mobile
  players are eliminated.

### 4. Game End

- **Timer expires with the core alive:** VR wins.
- **All mobile players eliminated:** VR wins.
- **Core destroyed:** Mobile players win.
- Leaderboard displays on the shared screen.

## Results and Ranking

**Individual mobile ranking:** Survivors rank first, by lives remaining, then time
survived. Eliminated players rank by elimination order — the last player eliminated
ranks highest.

**Leaderboard:** Shows the winning side and elimination order. On a mobile win, it
also shows damage dealt.

## Shared Screen and HUD

The shared desktop view shows the 3D arena and a lightweight HUD.

| Element | Description |
|---------|-------------|
| Timer | Countdown from 3 minutes, prominent center-top |
| Core health | Bar showing the core's remaining health |
| Leaderboard | Shown after the round ends |

## Presentation

### Visual States

| State | Visual |
|-------|--------|
| Normal (5.0–6.5m/s) | Soft glow, short trail |
| Fast (6.5–8.0m/s) | Bright glow, long trail, slight screen shake on VR block |
| Very fast (8.0–10.0m/s) | Intense glow, particle trail, arena edge pulse on block |
| **Reflect Boost** (any speed +2.0m/s, up to 12.0m/s) | **White-hot core with colored afterimage trail**, pulsing glow, heavy screen shake, audio pitch shift up |
| **Turbo Power-up** (+2.0m/s, up to 12.0m/s) | Original orb color with golden shimmer, particle trail, steady bright glow |

**Distinguishing Reflect Boost from Turbo:** Reflect Boost orbs have a white-hot
core with an afterimage trail (fading copies of the orb), while Turbo orbs keep
their original color with a golden shimmer. This lets players instantly tell whether
an orb was overcharged by the VR player or picked up a power-up.

### Audio Layers

- **Base:** Ambient vortex hum, constant.
- **Per orb:** Whoosh on launch, impact crack on VR block, shatter on life lost.
- **Reflect Boost:** Pitch shift up while boosted; descending tone when boost expires.
- **Music:** Tempo increases with the number of boosted orbs in play. At 3+
  boosted orbs, add a bass layer.
- **Crowd reactive:** Cheers on elimination, gasps on close dodges, roar at 60+
  seconds if 3+ players are still alive.


