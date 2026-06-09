# 008 — Ecto-Vacuum Capture & Rescue Loop

## Source GDD

`gdd/GHOST_HUNTER.md` → VR Player → Ecto-Vacuum, Capture sequence, Haunt (rescue)

## What to build

The Ecto-Vacuum is the Hunter's capture tool — the win-condition mechanic. When the Hunter spots a revealed ghost, they aim the vacuum and hold the trigger. After 3 seconds of continuous suction, the ghost is captured and stored inside the vacuum.

While sucking, the Hunter moves at reduced speed — creating a risk/reward tension: commit to the capture and become vulnerable, or stay mobile and let the ghost escape.

Captured ghosts aren't out permanently. Any free ghost can approach the vacuum, haunt it (using the Haunt mechanic from task 006), and press A to release one captured ghost at a time. This creates a tug-of-war: the Hunter captures, ghosts rescue.

The Hunter can counter rescues by Flashing a haunted vacuum — this purges the possessing ghost out and resets the rescue attempt, protecting the captured ghosts inside.

## Acceptance criteria

- [ ] Ecto-Vacuum is a tool the VR player holds/aims (visible in first-person)
- [ ] Holding the trigger activates suction — visual beam/stream effect from vacuum forward
- [ ] Suction only affects revealed ghosts within the vacuum's range and cone
- [ ] Ghost being sucked is visibly pulled toward the vacuum (force/movement toward Hunter)
- [ ] 3 seconds of continuous suction on a revealed ghost → ghost is captured
- [ ] If the ghost escapes the suction cone before 3 seconds, progress resets
- [ ] Hunter movement speed reduced by ~50% while actively sucking
- [ ] Captured ghost is stored in the vacuum (visual indicator: ghost icon on vacuum, ghost removed from shared screen)
- [ ] Free ghost can approach the vacuum (within haunt range) + A → haunts the vacuum
- [ ] Haunted vacuum shows a visual indicator (flickering, distorted effect)
- [ ] Haunting ghost presses A → releases one captured ghost (reappears next to vacuum)
- [ ] Hunter can Flash a haunted vacuum → purges the haunting ghost out (forced exit, no rescue completed)
- [ ] Flashed ghost from vacuum is revealed (visible for 4s like normal Flash)
- [ ] Captured ghosts that remain in the vacuum at round end count toward Hunter's win progress

## Blocked by

- [004-vr-hunter-flash-visibility](./004-vr-hunter-flash-visibility.md) — needs Flash Device and visibility system
- [006-haunt-interactive-objects](./006-haunt-interactive-objects.md) — needs Haunt mechanic for rescue interaction

## Design notes

- Suction progress: show a fill bar or ring on the Hunter's HUD while sucking a ghost
- Ghost pull force: the ghost should feel a tug toward the vacuum but not be instantly locked — gives the ghost a chance to struggle/escape
- The vacuum stores captured ghosts as a list — release order is LIFO (last captured, first released) for simplicity
- Make the vacuum a physics-aware object that ghosts can path to (not something the Hunter can hide in an unreachable corner)
- Integration with task 004: Flash purges haunted objects — make sure the vacuum is treated as a "hauntable" when a ghost is inside it
