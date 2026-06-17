---
name: create-spec
description: >-
  Use when the user describes a change request, feature proposal, bug report, or
  refactor idea and wants a detailed technical specification and updated
  documentation. The skill investigates the request, surveys docs and codebase,
  updates affected documentation, and produces a specification task file in
  docs/tasks/. Do NOT use for direct code changes or bug fixes — use only when
  the user asks for a specification to be created before implementation.
---

# Create Specification

Transform a change request (feature, bugfix, refactor, design tweak) into a
structured specification. The work has three deliverables:

1. **Updated Documentation** — edit affected docs to reflect the approved design
2. **Specification Task** — a `docs/tasks/<TASK_NAME>.md` file ready for
   implementation
3. **Open Questions Resolved** — every ambiguity addressed before the spec is
   finalised

---

## Process

### 1. Understand the change request

Read the user's description carefully. If it's ambiguous, ask clarifying
questions before proceeding. Establish:

- **What** is being changed — the concrete deliverable
- **Why** it's needed — the motivation or problem
- **Scope** — what's in and what's explicitly out

### 2. Read existing documentation

Search the project's docs for anything relevant:

- `docs/GDD.md` — the main Game Design Document
- `docs/<GAME_NAME>.md` — individual game GDDs (e.g., `HIDE_AND_SEEK.md`)
- `docs/adr/*.md` — Architecture Decision Records
- `docs/tasks/*.md` — existing task definitions
- `docs/*.md` — any other documentation files

Use the `grep` and `glob` tools to find and read all possibly relevant docs.

Summarise what you find and which docs are affected.

### 3. Survey the codebase structure

Use `glob` and `grep` to identify:

- Which Godot scenes (`.tscn`), scripts (`.gd`), and resources (`.tres`) are
  relevant
- Which `main/` systems are involved (lobby, scoring, round orchestration,
  player join, etc.)
- Which `mods-unpacked/KumaGee-VRCore/<game-name>/` mini-games are affected
- Which `game-client/` SvelteKit code (if any) is involved

Do NOT read entire files unless necessary. Focus on structure and naming
conventions to identify affected surface area.

### 4. Present findings and resolve open questions

Share your analysis with the user. Structure it under these headings:

---

#### Updated Documentation (Proposed)

Which documentation files need changes and what those changes consist of.
Organise by file.

Example:

- **`docs/GDD.md`** — The Home World section needs a bullet for the new TV
  interaction ("VR player can toggle channel overlay"). No structural changes.
- **`docs/adr/ADR-0001-game-client-controller-only.md`** — No change needed
  (phone remains controller-only).
- **`docs/HIDE_AND_SEEK.md`** — A new section "Round Scoring" needs to be
  added under Round Flow. See [GDD scoring table](./HIDE_AND_SEEK.md#scoring).

#### Affected Systems

List every system, subsystem, scene, or module the change touches. For each,
describe the nature of the impact:

- **New** — a new system or component must be created
- **Modified** — an existing system needs changes
- **Removed** — a system is deprecated or deleted
- **Interface change** — signals, function signatures, or data contracts change

Group by area:

- **VR (main/):** scenes, scripts, resources in the core game
- **Mini-game (`mods-unpacked/KumaGee-VRCore/<name>/`):** game-specific files
- **Mobile (`game-client/`):** SvelteKit app, layout files, WebRTC protocol
- **Shared/Infrastructure:** lobby, scoring, networking, HTTP server, build

#### Open Questions

List every unresolved question that must be answered before the specification
can be finalised. Prefer concrete, actionable questions over vague ones.

Example:

- Should the new scoring rule apply retroactively to rounds in progress, or
  only to new rounds?
- What happens if a mobile player disconnects during the scoring animation?
- Is the "found feed" capped at N entries, or does it scroll indefinitely?
- Does the VR player need a haptic cue on wrong tag, or is visual-only
  sufficient?

---

Discuss each open question with the user until all are resolved and the user
approves the plan.

### 5. Update documentation and create specification

Once all open questions are resolved and the plan is approved:

#### 5a. Update all affected documentation

Edit the actual documentation files identified in **Updated Documentation**
(step 4). Apply the changes to reflect the approved design — add sections,
update tables, revise descriptions. Do not leave docs in a stale state.

#### 5b. Create the specification task file

Create `docs/tasks/<TASK_NAME>.md` following the project's existing task
document format. The file must contain:

```markdown
# <NNN> — <Task Title>

Reference: <links to relevant GDD sections, ADRs, or other docs>

## Summary

What the change is and why it's needed. A few paragraphs that give enough
context for a developer to understand the goal.

## What to build

A detailed description of what needs to be built. Cover:

- All new systems, scenes, scripts, or components
- All modifications to existing systems
- Behaviour, edge cases, and error handling
- Visual and interactive details where relevant

## Files touched

Every file that will be created or modified, with a one-line description of
the change per file.

## Data flow

How information moves through the system — signals, function calls, network
messages, state transitions. Be specific about signal names, function
signatures, and message formats where known.

## New signals / functions / classes

The API surface of any added code. Include:

- New signal names and their payloads
- New function signatures (name, parameters, return type)
- New classes and their public interface

## Migration / compatibility

Anything that changes for existing players, saved data, or network protocol.
If nothing changes, say "None — no breaking changes."

## Acceptance criteria

Checklist of concrete, testable outcomes. Each item must be verifiable by the
tester agent.

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] ...

## Blocked by

List of task numbers this depends on (e.g., `005`). If none, say "None — can
start immediately."
```

Choose the task number by finding the next available number in `docs/tasks/`.

#### 5c. Offer to begin implementation

Ask the user if they want the changes implemented now. If yes, they can invoke
the `implement-spec` command with the new task file.

---

## Rules

- **Do not write implementation code.** No GDScript, no TSCN fragments, no
  Svelte, no TypeScript. Refer to existing code by file/class/signal name,
  but do not produce new implementations.
- **Do update documentation.** If an existing doc is affected, edit it in step
  5a. Stale docs are technical debt.
- **Be specific.** Reference exact file paths (`docs/HIDE_AND_SEEK.md`
  not "the hide-and-seek doc"), system names (`LobbyServer` not "the lobby
  thing"), and signal/function names where known.
- **If you cannot determine something, flag it as an open question.**
- **Escalate contradictions.** If the change request contradicts an existing
  ADR or GDD section, call it out explicitly and flag it as an open question
  asking for a decision.
- **Match existing task format.** Follow the style, level of detail, and
  conventions of existing files in `docs/tasks/`.
