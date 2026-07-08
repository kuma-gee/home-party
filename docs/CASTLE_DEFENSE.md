# Castle Defense

The VR player defends a castle gate using a bow and elemental arrows against a horde
of skeletons. Mobile players control the skeletons, using catapults and bombs to
destroy the gate before the time runs out.

- **Time Limit:** 3 minutes
- **Win Condition (VR):** Gate survives to time
- **Win Condition (Mobile):** Gate reaches 0 HP
- **Recommended Players:** 4+

## VR Player

The VR player physically grabs arrows from their back, optionally slots them into one
of the **elemental orbs** placed directly in front of them to change the arrow's
element, then shoots by grabbing and pulling the bowstring.

The player equips up to **3 elements** at the start of the match — this is a meaningful
loadout decision based on expected mobile strategy.

### Arrows

All arrows deal **1 damage** — every skeleton dies in one hit. Elements are purely
about reach, area, and cooldown tradeoffs. Arrows with no element (None) are always
available as a no-cooldown fallback while elemental orbs recharge.

| Element   | Cooldown | Effect |
|-----------|----------|--------|
| None      | None     | Single target |
| Fire      | 1.5s     | Explosion on hit — kills all skeletons in a small radius (~2m) |
| Ice       | 4s       | freezes all skeletons in a medium radius (~4m) for 3s; lingering slow for 6s after |
| Wind      | 3.5s     | Doesn't kill — create a moving tornado that pulls all skeletons within the area (~6m); bomb carriers keep their fuse ticking |
| Lightning | 4.5s     | chains to 2 nearby skeletons within ~5m |
| Poison    | 2.5s     | emits a cloud (~4m) on impact — skeletons inside it die after 5s. Poisoned skeletons can inject others nearby |

**Design Intent**

- **None** — reliable fallback, no cooldown, single target. Should feel like a safety net, never a punishment for missing a cooldown window.
- **Fire** — runner-killer; fast cooldown, small AoE punishes tight groups. Should feel like a quick, satisfying "pop" — the reward for tracking a cluster instead of a single target.
- **Ice** — catapult suppressor; freeze locks crews mid-charge, lingering slow denies repositioning. Should feel like a decisive, momentum-stopping shutdown of a crew that was about to pay off.
- **Wind** — denial tool; resets runner and catapult progress without killing; especially punishing against bomb carriers whose fuse keeps ticking during knockback. Should feel darkly funny rather than just annoying — watching a runner get yanked back while their own bomb fuse keeps burning is the payoff.
- **Lightning** — crowd clearer; one shot can wipe a full catapult crew, but the long cooldown makes it a commitment. Should feel like a high-tension bet that pays off big — a full-crew wipe should read as a spectacle moment, not just a number.
- **Poison** — punishes clustering; the lingering poison means even runners who escape the cloud will die after 5s; useless against solo runner. Should feel like a slow-building inevitability — a runner who thinks they escaped realizing they didn't.

### Feedback & Juice

Hit feedback that already exists in the build: bow draw/release sounds, per-element
impact VFX with dedicated audio for Ice (frost/blizzard), Lightning (bolt), Poison
(cloud), and Wind (tornado). Poisoned skeletons get a green tint plus a pulsing
head-icon that shifts white→red as their timer runs out. Frozen skeletons visibly
lock into their animation pose. **Known gap:** Fire's impact currently has no
dedicated sound layer (VFX only), and the gate has no staged damage visuals — only
a plain health bar — so HP loss isn't legible at a glance without checking it.

## Mobile Players

Mobile players spawn as skeletons and can move freely around the map.
Their main offensive options are crewing a catapult or running a bomb to the gate,
but they can also dodge arrows, pick up stray bombs.

These two offensive options define the game's two emergent player archetypes,
referenced throughout this doc:

- **Runner** — a skeleton carrying a bomb toward the gate, racing the fuse
- **Catapult crew** — one or more skeletons charging a catapult from a fixed position

### Respawn

Respawn time scales linearly with the number of active players, spawning at a fixed point away from the gate.
- 2 players: 2s
- 6+ players: 6s
- Values in between are interpolated (e.g., 4 players ≈ 4s)

### AI Skeletons (solo mode)

If **zero** mobile players are connected, the VR player can practice solo against
AI-controlled skeletons instead of humans — this is all-or-nothing, AI never fills
just the empty slots in a partial lobby. AI count is adjustable from 2–10 (default 4)
via +/- buttons on an in-world lobby panel before the match starts. In this mode, Gate
HP scales off the configured AI count (using the same table below), but respawn time
does not — AI agents always respawn at the fastest (2s) rate regardless of count,
since respawn scaling is keyed off human player count, which is 0 in a solo match.
The "Recommended Players: 4+" figure above refers to human mobile players.

### Firepower

All mobile weapon damage is multiplied by the player's personal **firepower** value.
Each player tracks their own firepower independently — a powered-up player at a
catapult deals more damage.

Firepower increases by +1 each time that player successfully delivers a bomb
to the gate. Everyone starts with a firepower of 3.

### Catapults

Two catapults sit on the left and right sides of the map. Multiple players
can crew the same catapult to charge faster and increase the damage

### Bombs

Four bombs spawn in the middle of the map with a 3s respawn rate. Only 1 bomb can be carried at a time.
Taking the bomb to the gate, damages it and the player can respawn at a faster spawn time.

- Picking up a bomb starts an **10s fuse** — it explodes on the carrier if not delivered in time
- **Successful delivery:** deals `1 × firepower` damage to the gate and grants the carrier **+1 firepower**
- **Dying mid-run:** no gate damage, no firepower gain

---

## Onboarding

Before the match timer starts, each side gets a short, role-specific tutorial during
the prepare phase:

- **VR player** — a 2-page panel: page 1 explains the goal ("Protect the gate for 3
  min") and controls ("Grab arrow behind your head", "Put tip inside the orb",
  "Release on top of bow and pull string"); page 2 is the element-select screen where
  the player picks their loadout of up to 3 elements. Once the match starts, live
  in-world prompts reinforce the same steps the first time the player picks up the
  bow, grabs an arrow, and slots an element, then disappear.
- **Mobile players** — a screen reading "Destroy the gate within the time limit" with
  two icon+text hints: "Stand near catapult" and "Take bomb to the gate (increases
  firepower)". After spawning, a brief "Press [button] to spawn" hint also appears
  for first-time players, then auto-hides.

---

## Gate

Gate HP scales invisibly with player count, consistent with the respawn time scaling pattern.

| Players | Gate HP |
|---------|---------|
| 2       | 40      |
| 3-4     | 55      |
| 5-6     | 75      |
| 7+      | 100     |

### End of Match

**Losing (gate destroyed):** declared instantly, no grace period — the moment the
gate's HP hits 0, the destruction VFX/sound plays and the match ends.

**Winning (timer expires with gate alive):** not instant — a scripted ~4-second
epilogue plays out first. The win sound plays and the gate is immediately locked
(no longer destructible), then a barrage of meteorite sieges (separate from the
player-operated catapults) fires at the gate one by one, staggered 0.5-1.5s apart,
purely for spectacle since the gate can no longer take damage. "Castle survived!"
is declared on a fixed 4s timer after that, not when the meteorites finish animating.

---

## Future Considerations

> **Void:** A sixth element exists in the codebase with a 5s cooldown, creating
> a black hole that pulls in and deletes skeletons. It is currently disabled
> in the element selection UI and not available for players to equip.
> **Status: parked, not on the active roadmap.**