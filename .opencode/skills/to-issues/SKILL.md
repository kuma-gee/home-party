---
name: to-issues
description: Break a game design document (GDD) into independently-grabbable implementation issues using tracer-bullet vertical slices. Use when user wants to convert a tasks or changes into tickets, create implementation tasks, or break down game mechanics into work.
---

# To Issues (GDD → Tickets)

## Process

### 1. Gather context

Work from whatever GDD or content is already in the conversation context.
If the user passes a GDD reference (path or URL) as an argument, read it.
The project GDD lives at `docs/GDD.md`. 

### 2. Explore the codebase

Explore the codebase to understand the current state of implementation — what systems
already exist, what patterns are used, and what's already wired.

### 3. Draft vertical slices

Break the GDD or changes into **tracer bullet** issues. Each issue is a thin vertical slice
that cuts through ALL integration layers end-to-end. NOT a horizontal slice of one layer.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer
- A completed slice is playable or verifiable on its own — you can test the mechanic end-to-end
- Prefer many thin slices over few thick ones
- Slice by mechanic, not by layer: "arrow shooting" is a slice, not "VR rendering" separately from "collision detection"
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name (use GDD domain language)
- **Blocked by**: which other slices (if any) must complete first
- **GDD sections covered**: which GDD sections or mechanics this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?

Iterate until the user approves the breakdown.

### 5. Create the issues

For each approved slice, create a new issue in the `tasks` folder as one markdown file.
Number the files in dependency order (blockers first) so the issue identifiers can be
referenced in the "Blocked by" field. For example, if "Implement arrow shooting" must be done
before "Implement skeletons reacting to arrows", number the former `001-arrow-shooting.md`
and the latter `002-skeleton-reactions.md`.

<issue-template>
## Source GDD

Reference the GDD document and section(s) this slice implements (e.g., `docs/CASTLE_DEFENSE.md#catapults`).

## What to build

A concise description of this vertical slice. Describe the end-to-end mechanic, not
layer-by-layer implementation. What does the player experience? What systems participate?
Avoid specific file paths or code snippets — they go stale fast.
Trim to the decision-rich parts — not a working demo, just the important bits.

## Acceptance criteria

- [ ] Criterion 1 (e.g., "Player can fire an arrow that explodes on skeleton hit")
- [ ] Criterion 2 (e.g., "Skeleton hit by explosion is removed from the game")
- [ ] Criterion 3 (e.g., "Fire arrow cooldown indicator works on HUD")

## Blocked by

- A reference to the blocking ticket (if any)

Or "None - can start immediately" if no blockers.

</issue-template>
