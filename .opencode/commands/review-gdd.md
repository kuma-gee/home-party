---
name: review-gdd
description: >-
  Review a Game Design Document (GDD) for clarity, completeness, internal
  consistency, cross-document alignment, and implementation readiness. Use when
  the user says "review this GDD", "review the game design", "check this doc",
  or passes a path to a GDD file like `docs/CASTLE_DEFENSE.md`.
---

# Review Game Design Document

Perform a structured review of a Game Design Document to surface issues before
implementation begins. The review focuses on **design quality** — clarity,
completeness, consistency, feasibility — not on style or grammar.

## Usage

```
review-gdd <file>
```

Where `<file>` is a path relative to the project root (e.g., `docs/CASTLE_DEFENSE.md`).
If no file is provided, default to `docs/GDD.md`.

## Process

### 1. Read the target GDD

Read the specified file. If the file is a child page referenced from a parent
GDD (e.g., `docs/CASTLE_DEFENSE.md` referenced from `docs/GDD.md#games`), also
read the parent GDD to understand the broader context.

Identify the doc's **type**:

| Type | Description |
|------|-------------|
| **Root GDD** | The top-level `docs/GDD.md` — describes the overall game, shared systems, lobby, and links to per-game docs |
| **Per-game GDD** | A game-specific doc like `docs/CASTLE_DEFENSE.md` — describes one mini-game in detail |
| **ADR** | An architecture decision record in `docs/adr/` — skip, not a design doc |
| **Spec / Task** | A task file in `docs/tasks/` — skip, not a design doc |

Only review root GDDs and per-game GDDs.

### 2. Structural Completeness

Check that the GDD contains the expected sections for its type.

#### For a Per-game GDD (e.g., `docs/CASTLE_DEFENSE.md`):

Expected sections:
- **Overview / Elevator Pitch**: 1–3 sentences explaining the game concept — present / missing
- **Player counts**: Min/max/recommended — present / missing
- **Time limit**: Round or match duration — present / missing
- **Win conditions**: How each side wins — present / missing
- **VR Player section**: Controls, abilities, tools, constraints — present / missing
- **Mobile Player section**: Controls, abilities, constraints — present / missing
- **Shared / Environment section**: Shared space, gate, board, etc. — present / missing
- **Scoring / Progression**: How points work, if any — present / missing
- **End conditions**: How the game ends — present / missing
- **Design pillars / intent**: Why design choices were made — recommended

List any missing sections as **Structural Gaps**.

### 3. Clarity & Specificity Review

Review each section of the GDD for vague or ambiguous language. Flag:

- **Vague weasel words**: "some", "various", "appropriate", "certain", "eventually" — anything that defers a concrete decision
- **Unspecified numbers**: "a few seconds", "a small area", "some damage" — prefer exact values or ranges
- **Undefined terms**: Terms used but never explained (e.g., "firepower" without definition)
- **Missing edge cases**: What happens when things go wrong? (disconnect, timeout, tie, empty pool, etc.)
- **Unclear responsibilities**: "the system handles it" — which system? How?
- **Incomplete flows**: Steps missing between start and end (e.g., "player submits a word" but no description of validation)

For each issue found, quote the relevant text and explain the ambiguity.

### 4. Internal Consistency Check

Scan the document for contradictions or conflicting rules:

- **Conflicting numbers**: Two places that state different values for the same thing (e.g., cooldown stated in one table but a different value in prose)
- **Conflicting rules**: Mechanics that contradict each other (e.g., "elemental arrows have cooldowns" but one element says "no cooldown" — that's fine, but "fire does 2 damage" and later "all arrows do 1 damage" is not)
- **Conflicting design intent**: A stated design pillar that contradicts actual mechanics (e.g., pillar says "everyone plays every round" but a mechanic eliminates players)
- **Broken references**: Links to sections that don't exist, or references to mechanics not described anywhere

### 5. Completeness & Gap Analysis

Identify missing details that would block implementation:

- **Missing states**: What states does the game have? (lobby, pre-game, playing, paused, ended, results) Are transitions between states documented?
- **Missing error handling**: What happens on mobile player disconnect mid-round? What happens if no mobile players join?
- **Missing resource requirements**: Are there new assets needed? (models, sounds, UI elements, animations) Are they described?
- **Missing constraints**: Are there technical constraints not acknowledged? (VR performance, mobile bandwidth, controller button limits)

### 6. Feasibility Flags

Flag anything that might be problematic to implement given the existing codebase:

- **Architecture mismatch**: Does the GDD describe something that conflicts with existing shared systems?
- **Scope creep**: Does the GDD describe something that seems over-scoped for a mini-game? (complex AI, networking, persistence)
- **VR safety**: Any mechanics that might cause VR discomfort? (forced movement, sudden camera changes, disorienting effects)
- **Platform constraints**: Anything that won't work on the target platforms (WebXR, phone browser)?

### 7. Summary Report

Produce a structured summary:

```markdown
## GDD Review Summary

**Document:** <path>
**Type:** Root GDD / Per-game GDD
**Reviewed sections:** <count>

### Structural Gaps (<count>)
- ...

### Clarity Issues (<count>)
- ...

### Internal Inconsistencies (<count>)
- ...

### Completeness Gaps (<count>)
- ...

### Feasibility Flags (<count>)
- ...

### Overall Verdict
**Ready for implementation:** Yes / No / With caveats

If "With caveats" or "No", list the blocking issues that must be resolved
before implementation can start. Prioritize them as:
- **BLOCKING**: Must fix before implementation
- **IMPORTANT**: Should fix before implementation
- **NICE-TO-HAVE**: Can defer to implementation phase
```

## Rules

- Do NOT rewrite the GDD — only identify issues with recommendations
- Do NOT add new design content or decisions
- Do NOT evaluate implementation quality (that's for code review)
- Be specific: quote exact text and line numbers where issues are found
- Be constructive: every issue should include a recommendation for how to clarify or fix it
- Stop and report if the file cannot be read or is not a GDD
