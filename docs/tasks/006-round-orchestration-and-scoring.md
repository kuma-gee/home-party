# 006 — Round Orchestration and Scoring

Reference: `docs/HIDE_AND_SEEK.md` — Round Flow (Setup → Hunt → End), Scoring table, Shared Screen (timer, hider count, found feed, scoreboard)

## What to build

The full round lifecycle and scoring system that ties everything together.

**Round flow:** The game runs through three phases:
1. **Setup (8s)** — Hiders pick props (004). VR player sees a black screen or "Waiting" overlay. Timer counts down from 8.
2. **Hunt (2 min)** — VR player searches. Hiders use movement, distract, and swap. Timer counts down from 2:00.
3. **End** — Triggered either by all hiders found (VR wins) or by the timer expiring (hiders win).

**Scoring** per the GDD table:
- VR: +1 per hider found, +3 bonus if all found
- Hider: +3 for surviving the round, +2 bonus for last survivor, +1 bonus for using distract

**Shared screen** shows the full game HUD:
- Live 2:00 countdown timer
- "X hiding" hider count badge (updates as players found)
- Found feed (list of recently found hiders scrolling up)
- End-of-round scoreboard / leaderboard

**Play-again flow:** After the scoreboard, players can vote or the host can start a new round. Props and room reset to initial state.

## Acceptance criteria

- [ ] Round flow: Setup (8s) → Hunt (2:00) → End, with clear transitions
- [ ] VR player sees black screen or "Preparing..." overlay during setup phase
- [ ] Mobile players can pick props during setup phase
- [ ] Timer on shared screen counts down correctly during setup and hunt
- [ ] Hunt ends immediately when all hiders are found (VR victory)
- [ ] Hunt ends when timer reaches 0 with at least one hider remaining (hider victory)
- [ ] VR player sees a clear "Victory" or "Defeat" screen at round end
- [ ] Mobile players see "You survived!" or "Found!" screen at round end
- [ ] Shared screen shows a scoreboard/leaderboard at round end
- [ ] Scoring is applied correctly for all outcomes (per GDD table)
- [ ] VR player gets +3 bonus if they found all hiders
- [ ] Last surviving hider gets +2 bonus
- [ ] Hider gets +1 bonus for each distract used
- [ ] "Play again" flow works: room resets, props return to original positions, new round starts
- [ ] Found feed on shared screen shows entries (e.g., "Alice found!" → scrolls up)

## Blocked by

- 005 — Distract and Swap
