# 010 — Haunt Surge, Win Conditions & Scoring

- [ ] Approved by user

## What to build

This is the endgame — the round's climax and resolution. When all Mischief Tasks are completed, the Haunt Surge triggers: all remaining ghosts become fully visible (no Flash needed), slowed by 30%, and a 30-second timer starts. Ghosts must touch the Hunter to win. The Hunter must survive without being touched.

Win conditions for the Hunt Phase:
- **Ghosts win** — all tasks completed (triggers Haunt Surge) AND either touch the Hunter during Surge, or simply complete all tasks (Hunter can still win during Surge by surviving)
- **Hunter wins** — all ghosts captured before tasks complete, OR survive the full 30-second Haunt Surge without being touched
- **Draw** — Hunter reaches the exit during Haunt Surge without being touched

Scoring distributes points based on outcome, with three bonus categories tracked throughout the round:
- **Bamboozle** — ghost tricks Hunter into wasting a Flash with no ghost in range
- **Rescue** — ghost successfully frees a captured teammate
- **Clutch Capture** — Hunter catches the final ghost in the last 10 seconds of the round

End screens show results on both VR (via `xr_player.gameover()`) and shared screen.

## Acceptance criteria

### Haunt Surge
- [ ] Haunt Surge triggers immediately when all Mischief Tasks are completed
- [ ] Dramatic audio/visual cue on both VR and shared screen when Surge begins (lights dim red, siren/ghost wail)
- [ ] All remaining ghosts become fully visible to the Hunter (no Flash needed)
- [ ] All ghosts slowed by 30% during Haunt Surge
- [ ] 30-second survival timer starts — displayed on both VR HUD and shared screen
- [ ] Ghost can touch the Hunter to win (proximity collision trigger in 3D space)

### Win Conditions
- [ ] **Ghosts win** — any ghost touches the Hunter during Haunt Surge → round ends, ghosts win
- [ ] **Hunter wins (capture)** — all ghosts captured before all tasks complete → round ends, Hunter wins
- [ ] **Hunter wins (survival)** — Hunter survives full 30s of Haunt Surge without being touched → Hunter wins
- [ ] **Draw** — Hunter reaches designated exit point during Haunt Surge → draw (no points)
- [ ] Win condition is evaluated and round ends immediately when triggered

### Exit Point
- [ ] Exit point is marked in the house (e.g., front door glowing)
- [ ] Exit is only active during Haunt Surge
- [ ] Hunter reaching the exit during Haunt Surge triggers draw condition

### Scoring
- [ ] **Hunter wins** → VR player receives full points (value TBD, marked `[PLACEHOLDER]`)
- [ ] **Ghosts win** → points split among surviving ghosts proportional to tasks each completed
- [ ] **Draw** → no points awarded to either side
- [ ] **Bamboozle bonus**: tracked when Hunter uses Flash with zero ghosts in the cone → bonus points for ghost team
- [ ] **Rescue bonus**: tracked when a ghost successfully releases a captured teammate → bonus points for that ghost
- [ ] **Clutch Capture bonus**: tracked when final ghost is captured in last 10 seconds → bonus points for Hunter
- [ ] All score values marked `[PLACEHOLDER]` with tuning notes

### Gameover Screens
- [ ] VR gameover screen: shows win/lose/draw, personal score, highlights (bonuses earned)
- [ ] Shared screen gameover: shows per-player scores, who won, bonuses earned by each ghost
- [ ] Gameover flow ends with return to hub (standard `load_scene` transition)

## Blocked by

- [004-vr-hunter-flash-visibility](./004-vr-hunter-flash-visibility.md) — needs Flash (for Bamboozle tracking) and visibility toggle (for Haunt Surge reveal)
- [005-ghost-phase-walk](./005-ghost-phase-walk.md) — ghosts need to reach the Hunter during Surge
- [007-mischief-tasks](./007-mischief-tasks.md) — Haunt Surge triggers on task completion
- [008-ecto-vacuum-capture-rescue](./008-ecto-vacuum-capture-rescue.md) — needs capture state (for Hunter win condition, Rescue bonus)

## Design notes

- Haunt Surge ghost speed: 30% slow is a starting value — goal is to make ghosts catchable but still threatening if the Hunter panics
- Exit point: place it far from the Hunter's typical position so reaching it is a meaningful choice during Surge
- Bamboozle detection: check on each Flash use whether any ghost was in the cone. Track per-ghost who was closest/none.
- Clutch Capture: check if capture happens when round timer ≤ 10 seconds remaining
- All score values should use `StatsManager` for consistency with other games
- Gameover screens can follow Castle Defense's pattern: `xr_player.gameover(message)` for VR, populate a `desktop_gameover` Control node for shared screen
