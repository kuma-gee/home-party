---
name: verify-feature
description: >-
  Verify implemented features or bug fixes by launching the tester subagent to
  run through test cases against the running game. Use this after implementing a
  change (feature, bugfix, refactor) to confirm it works correctly. This is the
  "Run verification skill" step referenced in the developer workflow.
---

# Verify Feature / Bug Fix

After implementing a feature or bug fix, use the **tester** subagent to verify
the change works correctly in the running game. The tester will start the game,
execute test cases, and report results.

**Do not run this skill yourself.** Delegate verification to the tester
subagent via the `task` tool.

## Process

### 1. Gather context

Collect everything the tester needs to understand what to verify:

- **Specification path** — Which document describes the feature or bug fix?
  Look for:
  - `docs/tasks/<TASK_NAME>.md` — technical specification
  - `docs/<GAME_NAME>.md` — GDD for mini-game features
  - `docs/GDD.md` — main Game Design Document
  - `docs/adr/*.md` — Architecture Decision Records

- **Change summary** — What was implemented or fixed? Summarise concisely:
  - Feature: what was added and how it should behave
  - Bug fix: what was broken, what the expected behaviour is now

- **Git diff / commit** — The actual code changes. Check with `git diff` or
  `git log -1` if a recent commit exists.

- **Files changed** — Which scenes, scripts, resources, or config files were
  modified or created.

### 2. Launch the tester subagent

Use the `task` tool with `subagent_type: "tester"` and delegate verification.
The prompt must include:

1. **What changed** — a clear description of the feature or fix
2. **Where to look** — specification file paths, scene/script paths
3. **Test scenarios** — concrete things to test (see "Test scenarios" below)
4. **Expected outcomes** — what correct behaviour looks like

If context from step 1 is large, include file paths and let the tester read
them directly. Prefer concise delegation over bloated prompts.

### 3. Collect results

The tester subagent returns a summary of:

- **What passed** — each test scenario that worked correctly
- **What failed** — each test scenario that did not work, with details
- **Problems encountered** — testing environment issues (missing config,
  connectivity, test gaps)
- **Improvement suggestions** — how to make future testing more reliable

Forward this report to the user with a summary of what was verified.

### 4. Handle failures

If any test case fails:

- Analyse the failure (read logs, check code, inspect the scene)
- If it's a real bug, fix it and re-run the skill to confirm the fix
- If it's a test setup issue (wrong config, missing data), adjust and re-run
- If the spec is wrong or incomplete, flag it to the user

## Test scenarios

When writing the prompt for the tester, include test scenarios relevant to the
type of change:

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

- Do not test yourself — always delegate to the tester subagent
- Do not skip the verification step even for "trivial" changes
- If the tester reports problems with the testing environment, note them
  but do not modify the environment unless explicitly approved
- If no specification exists for the change, write a minimal description
  inline in the tester prompt instead
