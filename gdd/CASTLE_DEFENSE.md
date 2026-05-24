# Castle Defense

The VR player defends a castle gate using a bow and elemental arrows against a horde of skeletons. Mobile players control the skeletons, using catapults and bombs to destroy the gate before time runs out.

- **Time Limit:** 5 minutes
- **Win Condition (VR):** Gate survives to time
- **Win Condition (Mobile):** Gate reaches 0 HP
- **Recommended Players:** 4+

## VR Player

The VR player physically grabs arrows from their back, optionally slots them into one of three **elemental orbs** placed directly in front of them to change the arrow's element, then shoots by grabbing and pulling the bowstring.

The player equips **3 elements** at the start of the match — this is a meaningful loadout decision based on expected mobile strategy.

### Arrows

All arrows deal **1 damage** — every skeleton dies in one hit. Elements are purely about reach, area, and cooldown tradeoffs. Normal arrows are always available as a no-cooldown fallback while elemental orbs recharge.

| Element   | Cooldown | Effect |
|-----------|----------|--------|
| Normal    | None     | Single target |
| Fire      | 1s       | Explosion on hit — kills all skeletons in a small radius (~2m) |
| Ice       | 2s       | Kills hit target; freezes all skeletons in a medium radius (~4m) for 2s; lingering slow for 3s after |
| Wind      | 3s       | Doesn't kill — blasts hit target and all skeletons in a cone (~6m) back toward spawn; bomb carriers keep their fuse ticking |
| Lightning | 4s       | Kills hit target; chains to up to 3 nearby skeletons within ~5m |
| Poison    | 2.5s     | Kills hit target; corpse emits a cloud for 4s — skeletons entering the cloud (~3m) die after 4s unless they leave |
| Void      | 5s       | Creates a black hole at impact for 3s, pulling all skeletons within ~8m toward it, then explodes killing everything inside |

**Design Intent**

- **Normal** — reliable fallback, no cooldown, single target
- **Fire** — runner-killer; fast cooldown, small AoE punishes tight groups
- **Ice** — catapult suppressor; freeze locks crews mid-charge, lingering slow denies repositioning
- **Wind** — denial tool; resets runner and catapult progress without killing; especially punishing against bomb carriers whose fuse keeps ticking during knockback
- **Lightning** — crowd clearer; one shot can wipe a full catapult crew, but the long cooldown makes it a commitment
- **Poison** — punishes clustering; tag one skeleton heading to a catapult and let the cloud do the work; useless against solo runners
- **Void** — comeback button; highest cooldown, highest payoff; one well-placed shot can wipe a coordinated multi-threat push; Dash can escape the pull

## Mobile Players

Mobile players spawn as skeletons and choose between two strategies each life: charging a catapult shot or running a bomb to the gate.

### Respawn

Respawn time scales with player count, spawning at a fixed point away from the gate.

| Players | Respawn Time |
|---------|-------------|
| 4       | 6s          |
| 8+      | 3s          |

### Abilities

Players select one ability at the start of the game.

| Ability | Cooldown | Effect |
|---------|----------|--------|
| Dash    | 3s       | Short burst of speed (~2x for 0.5s); passes through Ice slow fields; can escape Void's pull if used quickly |
| Shield  | 5s       | Absorbs the next arrow hit completely; breaks after 1 hit |

**Design Intent**

- **Shield** is critical on a small map — it effectively halves the VR player's window to kill a runner
- **Dash** lets catapult crews escape Ice freeze zones and reposition quickly

### Firepower

All mobile weapon damage is multiplied by the player's personal **firepower** value. Each player tracks their own firepower independently — a powered-up player at a catapult deals more damage than a fresh spawn.

| Firepower | Catapult Damage | Bomb Damage |
|-----------|-----------------|-------------|
| 1 (start) | 2               | 1           |
| 2         | 4               | 2           |
| 3 (max)   | 6               | 3           |

Firepower increases by +1 each time that player successfully delivers a bomb to the gate. Cap is 3 (requires 2 successful bomb runs).

### Catapults

Two catapults sit on the left and right sides of the map. Multiple players can crew the same catapult to charge faster.

| Players at Catapult | Charge Time |
|---------------------|-------------|
| 1                   | 6s          |
| 2                   | 4s          |
| 3+                  | 3s          |

- At firepower 1: **2 dmg/shot** — gate needs 25 uncontested shots to fall
- At firepower 3: **6 dmg/shot** — gate falls in 9 uncontested shots; VR player must prioritize

### Bombs

Three bombs spawn in the middle of the map with a faster respawn rate than skeletons. Only 1 bomb can be carried at a time.

- Picking up a bomb starts an **8s fuse** — it explodes on the carrier if not delivered in time
- **Successful delivery:** deals `1 × firepower` damage to the gate and grants the carrier **+1 firepower**
- **Dying mid-run:** bomb drops and explodes after 3s at that location — no gate damage, no firepower gain

**Bomb Run Threat Model (small map)**

- Runner reaches the gate in ~5–10s — VR player gets roughly 3–6 shots
- At Fire spam (~1 arrow/1.5s avg): ~3–4 shots available — tight but killable
- A shielded runner absorbs 1 hit, making them very dangerous on a small map
- Wind doesn't kill but resets the runner's progress while their fuse keeps ticking — can force a self-destruct if timed well

---

## Gate

### Health Visibility

Gate HP is **not shown as a number** to mobile players. Progress is communicated through visible world-state changes.

| HP Range | Gate State |
|----------|------------|
| Full–70% | Intact |
| 70–40%   | Cracks, dust particles |
| 40–20%   | Visible damage, fire/sparks, intensified audio |
| 20–0%    | Barely holding — creaking, light bleeding through |

The VR player's HUD shows the numeric HP value for precise threat assessment.

### Health Scaling

Gate HP scales invisibly with player count, consistent with the respawn time scaling pattern.

| Players | Gate HP |
|---------|---------|
| 4       | 35      |
| 5–6     | 42      |
| 7–8     | 50      |
| 9+      | 58      |

---

## Balance

### Damage Budget (5 min, 4 players, both sides playing well)

| Source | Shots | Avg Damage | Total |
|--------|-------|------------|-------|
| Catapult (partially suppressed, mostly firepower 1) | ~12 | 2.5 | ~30 |
| Bomb runs (2–3 successful) | ~3 | 1.5 | ~5 |
| **Total** | | | **~35** |

Gate survives at ~15 HP with 4 players — VR player is comfortable. At 6+ players, more skeletons reach firepower 2–3, significantly increasing catapult pressure.

### Scaling with Player Count

| Players | Respawn | Catapult Pressure | Bomb Pressure | VR Difficulty |
|---------|---------|-------------------|---------------|---------------|
| 4       | 6s      | Low (1 per catapult) | Low | Manageable |
| 6       | 4.5s    | Medium (2+1 split) | Medium | Tense |
| 8+      | 3s      | High (2 per catapult + runners) | High | Chaotic |
