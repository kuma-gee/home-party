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
of three **elemental orbs** placed directly in front of them to change the arrow's
element, then shoots by grabbing and pulling the bowstring.

The player equips **3 elements** at the start of the match — this is a meaningful
loadout decision based on expected mobile strategy.

### Arrows

All arrows deal **1 damage** — every skeleton dies in one hit. Elements are purely
about reach, area, and cooldown tradeoffs. Arrows with no element (None) are always
available as a no-cooldown fallback while elemental orbs recharge.

| Element   | Cooldown | Effect |
|-----------|----------|--------|
| None      | None     | Single target |
| Fire      | 1.5s     | Explosion on hit — kills all skeletons in a small radius (~2m) |
| Ice       | 4s       | Kills hit target; freezes all skeletons in a medium radius (~4m) for 3s; lingering slow for 6s after |
| Wind      | 3.5s     | Doesn't kill — create a moving tornado that pulls all skeletons within the area (~6m); bomb carriers keep their fuse ticking |
| Lightning | 4.5s     | Kills hit target; chains to 2 nearby skeletons within ~5m |
| Poison    | 2.5s     | Kills hit target; corpse emits a cloud for 5s — skeletons entering the cloud (~4m) die after 5s. The poison persists once applied and cannot be removed by leaving the cloud |

**Design Intent**

- **None** — reliable fallback, no cooldown, single target
- **Fire** — runner-killer; fast cooldown, small AoE punishes tight groups
- **Ice** — catapult suppressor; freeze locks crews mid-charge, lingering slow denies repositioning
- **Wind** — denial tool; resets runner and catapult progress without killing; especially punishing against bomb carriers whose fuse keeps ticking during knockback
- **Lightning** — crowd clearer; one shot can wipe a full catapult crew, but the long cooldown makes it a commitment
- **Poison** — punishes clustering; tag one skeleton heading to a catapult and let the cloud do the work; the lingering poison means even runners who escape the cloud will die after 5s; useless against solo runners who avoid the cloud entirely

> **Void (disabled):** A sixth element (Void) exists in the codebase with a 5s cooldown, creating a black hole that pulls in and deletes skeletons. It is currently disabled in the element selection UI and not available for players to equip. It may be re-enabled in a future update.

## Mobile Players

Mobile players spawn as skeletons and can move freely around the map.
Their main offensive options are crewing a catapult or running a bomb to the gate,
but they can also dodge arrows, pick up stray bombs, and use active skills (dash,
shield) unlocked at the start of each life.

### Respawn

Respawn time scales linearly with the number of active players, spawning at a fixed point away from the gate.
- 2 players: 2s
- 6+ players: 6s
- Values in between are interpolated (e.g., 4 players ≈ 4s)

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