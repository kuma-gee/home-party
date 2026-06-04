---
name: to-issues
description: Break a game design document (GDD) into independently-grabbable implementation issues using tracer-bullet vertical slices. Use when user wants to convert a GDD into tickets, create implementation tasks, or break down game mechanics into work.
---

# To Issues (GDD → Tickets)

Break a GDD and any changes into independently-grabbable issues using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from whatever GDD is already in the conversation context.
If the user passes a GDD reference (path or URL) as an argument, read it.
The project GDD lives at `gdd/GDD.md` with per-game docs in `gdd/*.md`.
Also check if there are existing issues on the project tracker for prior art.

### 2. Explore the codebase

Explore the codebase to understand the current state of implementation — what systems
already exist, what patterns are used, and what's already wired.

### 3. Draft vertical slices

Break the GDD into **tracer bullet** issues. Each issue is a thin vertical slice
that cuts through ALL integration layers end-to-end (Godot VR systems,
WebRPC signaling, mobile controller UI, shared screen, synchronization),
NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as a
design review or playtest session. AFK slices can be implemented and merged without
human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (Godot scene/script, WebRPC message, mobile screen, shared display)
- A completed slice is playable or verifiable on its own — you can test the mechanic end-to-end
- Prefer many thin slices over few thick ones
- Slice by mechanic, not by layer: "arrow shooting" is a slice, not "VR rendering" separately from "collision detection"
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name (use GDD domain language)
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **GDD sections covered**: which GDD sections or mechanics this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. Create the issues

For each approved slice, create a new issue in the `tasks` folder as one markdown file.
Number the files in dependency order (blockers first) so the issue identifiers can be
referenced in the "Blocked by" field. For example, if "Implement arrow shooting" must be done
before "Implement skeletons reacting to arrows", number the former `001-arrow-shooting.md`
and the latter `002-skeleton-reactions.md`.

<issue-template>
## Source GDD

Reference the GDD document and section(s) this slice implements (e.g., `gdd/CASTLE_DEFENSE.md#catapults`).

## What to build

A concise description of this vertical slice. Describe the end-to-end mechanic, not
layer-by-layer implementation. What does the player experience? What systems participate?

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype
produced a snippet that encodes a decision more precisely than prose can (state machine,
network message schema, sync data structure), inline it here and note briefly that it came
from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Acceptance criteria

- [ ] Criterion 1 (e.g., "VR player can fire a fire arrow that explodes on skeleton hit")
- [ ] Criterion 2 (e.g., "Mobile skeleton hit by explosion is removed from the game")
- [ ] Criterion 3 (e.g., "Fire arrow cooldown indicator works on VR HUD")

## Blocked by

- A reference to the blocking ticket (if any)

Or "None - can start immediately" if no blockers.

</issue-template>
