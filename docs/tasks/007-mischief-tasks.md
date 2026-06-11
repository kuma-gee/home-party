# 007 — Mischief Tasks

- [ ] Approved by user

## What to build

Each round, ghosts receive a set of Mischief Tasks — objectives they must complete to trigger the Haunt Surge and win the round. Tasks appear as highlighted markers on the shared-screen map during the Setup Phase and persist through the Hunt Phase.

A ghost completes a task by standing near its marker for 3 uninterrupted seconds. Moving away resets the timer. The task pool is shared — any ghost can complete any task. The number of tasks scales with ghost count (2 for 1 ghost, 3 for 2, 4 for 3, 5 for 4+).

Task completion progresses the ghosts toward their win condition and feeds information to the Wrist Tablet (task 009).

## Acceptance criteria

- [ ] During Setup Phase (20s), task markers appear on the shared-screen map
- [ ] Task markers are visually distinct — e.g., glowing icons or pulsing circles at specific house locations
- [ ] Task count scales with ghost count: 2 tasks (1 ghost), 3 (2 ghosts), 4 (3 ghosts), 5 (4+ ghosts)
- [ ] Ghost standing within ~2 meters of a task marker starts a 3-second completion timer
- [ ] Completion timer shows progress visually on the shared screen (e.g., ring filling around the marker)
- [ ] Moving away before 3 seconds resets the timer to zero
- [ ] Completed task marker disappears or changes to a "done" state
- [ ] Multiple ghosts standing near the same task completes it faster (or at least doesn't break)
- [ ] Task completion is tracked globally — accessible for Haunt Surge trigger (task 010)
- [ ] Task completion generates a "ghost interaction ping" for the Wrist Tablet (integration point for task 009)

## Blocked by

- [002-house-environment](./002-house-environment.md) — needs house layout for task placement
- [003-ghost-player-movement](./003-ghost-player-movement.md) — needs ghost movement and position tracking

## Design notes

- Task markers should be placed at interesting house locations that force ghosts to move through risky areas (not all clustered in one safe room)
- Task types can be thematic but mechanically identical at this stage: "Scatter the books," "Unravel the curtains," "Shatter the mirror" — all use the same stand-near-marker mechanic
- The 3-second timer is a good starting point — may need tuning based on ghost count and house size
- Task completion events should emit a signal or update a shared state that tasks 009 and 010 can consume
