---
description: Verify implemented features or bug fixes against the running game
agent: tester
subtask: true
---

# Verify Feature / Bug Fix

Verify the change works correctly in the running game.

Target: $ARGUMENTS

If the target is empty, infer the most recent change from the conversation and
state what you are verifying before starting.

## Process

### 1. Gather context

Collect everything needed to understand what to verify:

- **Specification** — Read the relevant document if provided or discoverable:
  - `docs/tasks/<TASK_NAME>.md` — technical specification
  - `docs/<GAME_NAME>.md` — GDD for mini-game features
  - `docs/GDD.md` — main Game Design Document
  - `docs/adr/*.md` — Architecture Decision Records
- **Change summary** — What was implemented or fixed, and how it should behave.
- **Files changed** — Scenes, scripts, resources, or config files affected.

Ask for missing context instead of guessing when the target is ambiguous.

### 2. Build a TODO list

Create a TODO item for each concrete test scenario. See "Test scenarios" below.

### 3. Start the game

Launch the game via the Godot MCP bridge. If testing a mini-game, load the
`start-minigame` skill and start the relevant mini-game. Connect a mobile
player only if the scenario requires it (`connect-mobile-player`).

### 4. Run the scenarios

Execute each TODO item against the running game and record pass/fail with
details. Stop the game and website when finished.

### 5. Report results

Report:

- **What passed** — each scenario that worked correctly
- **What failed** — each scenario that did not, with observed behaviour
- **Problems encountered** — environment, connectivity, or test-gap issues
- **Improvement suggestions** — how to make future verification more reliable

## Test scenarios

### For a new feature

- Does the feature activate under the expected conditions?
- Does it produce the expected output / state change?
- Do edge cases work (empty state, max capacity, rapid input, disconnect)?
- Does it gracefully handle invalid input?

### For a bug fix

- Does the original bug no longer reproduce?
- Does the fix handle all variants of the original bug?
- Are there regressions in related features?
- Do the error bounds / edge cases work?

### For a UI / visual change

- Do the UI elements appear in the correct position and size?
- Do animations play correctly?
- Do all states (idle, active, error, disabled) display correctly?
- Do text labels show the correct values?

### For a networking / multiplayer change

- Can a second player connect?
- Do both players see the same game state?
- Does disconnect / reconnect work?
- Are network messages sent and received correctly?

## Rules

- Do not write or modify code.
- Do not skip scenarios even for "trivial" changes; report blockers if a
  scenario cannot be executed.
- If the testing environment has problems, note them but do not modify the
  environment unless explicitly approved.
- If no specification exists, test against the stated change summary and say so
  in the report.
