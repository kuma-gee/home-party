# 005 — Distract and Swap

Reference: `docs/HIDE_AND_SEEK.md` — Mobile Controls (Swap, Distract, cooldowns), Distract (directional sound, can't swap for 5s)

## What to build

Two depth mechanics for mobile hiders: **Distract** and **Swap**.

**Distract (Button B, 10s cooldown):** The mobile player emits a sound (creak, thud, or sneeze) from their prop's position. The VR player hears it directionally through 3D spatial audio. After distracting, the mobile player cannot swap props for 5 seconds.

**Swap (Hold Button A, 20s cooldown):** The mobile player targets a new prop in the room (same mechanic as setup — hold A to highlight nearest, release to transform). The old prop reverts to a static object, and the mobile player takes control of the new one. 20-second cooldown before they can swap again.

Both abilities have cooldown indicators shown on the phone UI. The existing A-button mechanic (move-to-highlight, release-to-select) is shared between setup and swap.

## Acceptance criteria

- [ ] Mobile player presses Button B → emits a random sound (creak/thud/sneeze) from their position
- [ ] VR player hears the sound directionally through 3D audio (turns head → sound pans correctly)
- [ ] Sound plays at full volume regardless of VR player's distance (design intent: it's a deliberate reveal)
- [ ] Mobile player sees "Distract" cooldown timer (10s) on phone after use
- [ ] Mobile player holds Button A near a new prop → nearest prop highlighted on phone
- [ ] Mobile player releases Button A on a new prop → transforms into new prop, old prop becomes static
- [ ] New prop is at its original resting position (mobile player "teleports" to it)
- [ ] "Swap" cooldown timer (20s) shown on phone after swap
- [ ] After distracting, swap is blocked for 5s (visual lock indicator on phone)
- [ ] Cannot swap or distract while VR player holds the mobile player's prop
- [ ] Cooldowns persist correctly across swap (distract cooldown doesn't reset on swap)
- [ ] Phone UI shows both cooldown rings/pips clearly

## Blocked by

- 004 — Mobile Hider
