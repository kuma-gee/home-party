# Castle Defense — GDD Implementation Gaps

## Bombs

- [ ] **Fuse timer:** GDD says **8s fuse**; verify current fuse duration in scene/code
- [ ] **Drop behavior:** GDD says dropped bomb explodes after **3s** at drop location; current code just `queue_free()`s the bomb on drop — no delayed explosion
- [ ] **Bomb count:** GDD says **3 bombs** spawn in the middle; current default is `bomb_count = 5`
- [ ] **Bomb respawn:** GDD implies bombs respawn faster than skeletons; current is `3.0s` — verify against final respawn times
- [ ] **Firepower gain timing:** GDD says firepower increases on **successful delivery**; confirm `reached_gate` signal only fires on actual gate contact

## Catapult

- [ ] **Charge times:** GDD specifies 6s (1 player), 4s (2 players), 3s (3+ players); current uses a logarithmic formula — does not match the table
- [ ] **Damage formula:** GDD says catapult damage = `2 × firepower` per shot; current boulder damage = `1 × sum of firepowers` — sum vs per-player multiply is a meaningful difference

## Gate

- [ ] **HP scaling:** GDD defines HP by player count (35/42/50/58); current HP is hardcoded in the scene HurtBox resource, not set dynamically
- [ ] **Visual state changes:** GDD specifies 4 visual states based on HP % (intact / cracks+dust / damage+fire / barely-holding); not implemented

## Respawn

- [ ] **Respawn times:** GDD says 6s at 4 players, 3s at 8+ players; current code interpolates 3–6s for 2–6 players — wrong curve

## Mobile Abilities

- [ ] **Shield:** GDD says shield absorbs **1 arrow hit** then breaks; current implementation is time-based (`1.0s` invulnerability) — should be hit-count-based
- [ ] **Firepower cap:** GDD caps firepower at **3** (requires 2 successful bomb runs); no cap enforced in current code

## Arrows / Elements

- [ ] **Ice:** GDD says freeze for **2s**, then lingering slow for **3s after**; current `freeze_time = 3.0s` total — duration mismatch
- [ ] **Ice radius:** GDD says ~4m; scene-defined, unverified
- [ ] **Fire radius:** GDD says ~2m; scene-defined, unverified
- [ ] **Wind radius:** GDD says ~6m; scene-defined, unverified
- [ ] **Lightning radius:** GDD says ~5m bounce range; scene-defined, unverified
- [ ] **Poison:** GDD says cloud lasts **4s**, kills after **4s** inside cloud; verify `poison_timer` duration in scene
- [ ] **Void:** GDD says black hole for **3s** then explodes killing everything inside; currently no `.gd` logic and **disabled** in element picker UI — needs full implementation

## UI / HUD

- [ ] **Gate HP — mobile:** GDD says mobile players must NOT see numeric HP; verify current `health_bar.gd` is hidden from mobile view
- [ ] **Gate HP — VR:** GDD says VR player sees numeric HP; verify a VR-specific HP display exists


Critical missing info:
1. 
Objectives never stated — "Survive 5 minutes" and "protect the gate" are never told to players before or during the game
2. 
Mobile skill descriptions missing — Dash and Shield have no explanation of what they actually do
3. 
How to fire the bow — tutorial only covers grabbing + loading an element, never explains pulling string/releasing to shoot
4. 
Mobile controls — zero onboarding for phone players on movement, attacking, or skill usage
5. 
Firepower (🔥 number) — shown on HUD but never explained to mobile players
6. 
Element switching mid-game — orbs are in the world but no instruction on how to change elements after the tutorial
7. 
Win/lose condition — never communicated pre-game, only shown as end-screen text
8. 
What catapults/bombs are — the 3-second flash is subtle and unexplained
9. 
Mobile players have no tutorial at all — all 3 tutorial steps are VR-only
Minor gaps:
- 
Skill cooldown duration not labeled (just a draining circle)
- 
No indication that mobile players respawn (they might think dying = game over for them)
- 
GameDetails panel on the menu shelf could explain the mode before players even start