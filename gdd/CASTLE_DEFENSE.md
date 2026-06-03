# Castle Defense

The VR player defends a castle gate using a bow and elemental arrows against a horde
of skeletons. Mobile players control the skeletons, using catapults and bombs to
destroy the gate before the time runs out.

- **Time Limit:** 5 minutes
- **Win Condition (VR):** Gate survives to time
- **Win Condition (Mobile):** Gate reaches 0 HP
- **Recommended Players:** 4+

## VR Player

The VR player physically grabs arrows from their back, optionally slots them into one
of three **elemental orbs** placed directly in front of them to change the arrow's
element, then shoots by grabbing and pulling the bowstring.

The player equips **3 elements** at the start of the match — this is a meaningful
loadout decision based on expected mobile strategy.

### Arrows

All arrows deal **1 damage** — every skeleton dies in one hit. Elements are purely
about reach, area, and cooldown tradeoffs. Normal arrows are always available as
a no-cooldown fallback while elemental orbs recharge.

| Element   | Cooldown | Effect |
|-----------|----------|--------|
| Normal    | None     | Single target |
| Fire      | 1s       | Explosion on hit — kills all skeletons in a small radius (~2m) |
| Ice       | 2s       | Kills hit target; freezes all skeletons in a medium radius (~4m) for 2s; lingering slow for 3s after |
| Wind      | 3s       | Doesn't kill — create a moving tornado that pulls all skeletons within the area (~6m) ; bomb carriers keep their fuse ticking |
| Lightning | 4s       | Kills hit target; chains to up to 3 nearby skeletons within ~5m |
| Poison    | 2.5s     | Kills hit target; corpse emits a cloud for 4s — skeletons entering the cloud (~4m) die after 4s unless they leave |

**Design Intent**

- **Normal** — reliable fallback, no cooldown, single target
- **Fire** — runner-killer; fast cooldown, small AoE punishes tight groups
- **Ice** — catapult suppressor; freeze locks crews mid-charge, lingering slow denies repositioning
- **Wind** — denial tool; resets runner and catapult progress without killing; especially punishing against bomb carriers whose fuse keeps ticking during knockback
- **Lightning** — crowd clearer; one shot can wipe a full catapult crew, but the long cooldown makes it a commitment
- **Poison** — punishes clustering; tag one skeleton heading to a catapult and let the cloud do the work; useless against solo runners
- **Void** — comeback button; highest cooldown, highest payoff; one well-placed shot can wipe a coordinated multi-threat push; Dash can escape the pull

## Mobile Players

Mobile players spawn as skeletons and choose between two strategies each
life: charging a catapult shot or running a bomb to the gate.

### Respawn

Respawn time scales with player count, spawning at a fixed point away from the gate.

| Players | Respawn Time |
|---------|-------------|
| 2       | 2s          |
| 8+      | 6s          |

### Firepower

All mobile weapon damage is multiplied by the player's personal **firepower** value.
Each player tracks their own firepower independently — a powered-up player at a catapult
deals more damage.

Firepower increases by +1 each time that player successfully delivers a bomb to the gate. Everyone starts with a firepower of 3.

### Catapults

Two catapults sit on the left and right sides of the map. Multiple players
can crew the same catapult to charge faster and increase the damage

### Bombs

Four bombs spawn in the middle of the map with a faster respawn rate than skeletons. Only 1 bomb can be carried at a time.

- Picking up a bomb starts an **10s fuse** — it explodes on the carrier if not delivered in time
- **Successful delivery:** deals `1 × firepower` damage to the gate and grants the carrier **+1 firepower**
- **Dying mid-run:** bomb explodes at that location — no gate damage, no firepower gain

---

## Gate

Gate HP scales invisibly with player count, consistent with the respawn time scaling pattern.

| Players | Gate HP |
|---------|---------|
| 2       | 40      |
| 3-4     | 55      |
| 5-6     | 75      |
| 7+      | 100     |