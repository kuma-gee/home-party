---
description: >-
  Analyse the current conversation, identify every open point, and create small
  vertical-slice tasks on the Trello board "AI Tasks" in the list "Home Party".
  Use when the discussion produced work that still needs to be done. Do NOT use
  when the user only wants a specification document or a direct code change.
---

# Create Tasks from Conversation

Turn everything discussed so far into actionable Trello tasks. The work has
three deliverables:

1. **Open Points Identified** — every undecided item, unimplemented request,
   unresolved question, and implied follow-up found in the conversation
2. **Slices Proposed** — each open point broken into small, independently
   deliverable vertical slices
3. **Trello Cards Created** — one card per slice on "AI Tasks" → "Home Party",
   with a description detailed enough to implement without re-reading the
   conversation

## Focus

$ARGUMENTS

If the focus above is empty, analyse the whole conversation. If it is non-empty,
treat it as a filter: still scan the whole conversation for open points, but
create cards only for points that match the focus.

---

## Process

### 1. Analyse the conversation

Scan the full conversation, not just the last message. Extract every open point:

- **Requests not yet implemented** — features, fixes, refactors, docs, tooling,
  command changes, config changes
- **Decisions left pending** — "we should probably…", "maybe later…", "needs a
  design decision"
- **Unresolved questions** — anything the user or agent left unanswered
- **Known gaps** — edge cases, error handling, tests, docs, and integration work
  mentioned but not done
- **Implied follow-ups** — work that logically follows from a completed change
  (migration, cleanup, verification, documentation update)

For each item record:

- What the conversation actually said (quote or paraphrase)
- Why it is still open (not implemented / not decided / not verified)
- Which part of the project it affects

**Do not invent work.** If an item only exists because you assume it is needed,
it is not an open point until the user confirms it.

### 2. Ground each item in the project

Before proposing a card, verify the item against the repository:

- Read the relevant docs: `docs/GDD.md`, `docs/<GAME_NAME>.md`,
  `docs/adr/*.md`
- Locate the affected area: `main/`, `mods-unpacked/KumaGee-VRCore/<game>/`,
  `game-client/`, `addons/`, `docs/`, `.opencode/`
- Confirm the work is not already done in code or already covered by an existing
  task or Trello card

Correct mistaken assumptions from the conversation using what the code actually
shows.

### 3. Resolve ambiguities before creating anything

List every question that blocks a clear task description. Ask the user directly.
Examples:

- Which player role owns this behaviour — VR player, phone player, or both?
- Should this ship behind a flag, or replace the current behaviour?
- Is the existing Trello card superseded, extended, or unaffected?
- Does "fix the lobby" mean the connection bug, the UI, or both?
- Should the mobile controller mirror this state, or stay controller-only?

**Never assume an answer.** If the user has not stated it, ask and wait. Do not
create a card with a guessed scope, guessed acceptance criteria, or a guessed
owner. TBD items are only acceptable when the user explicitly says the task is
to investigate the question.

### 4. Break work into vertical slices

A vertical slice is a thin, end-to-end piece of behaviour that can be
implemented, verified, and shipped on its own:

- **Good** — "VR player can see the hide-and-seek timer count down and the
  round ends when it reaches zero"
- **Bad** — "Add timer state to RoundManager" (horizontal layer with no visible
  outcome)
- **Bad** — "Implement hide-and-seek scoring, UI, networking, and audio"
  (multiple slices bundled together)

Rules for slicing:

- One card = one user-visible or externally observable outcome
- Each card must be independently implementable and verifiable by the tester
  agent without waiting for unrelated cards
- Prefer the smallest slice that still produces working behaviour
- If a slice must span VR and mobile, describe the player-visible outcome on both
  sides rather than splitting by layer
- Order dependent slices and record the dependency in the card, e.g. "Depends on:
  #<card>"
- Do not create speculative slices for work that is explicitly out of scope or
  being deferred
- Refactors, docs, and tooling are valid slices when they are the actual outcome

### 5. Present the plan and wait for approval

Show the user one block per proposed card:

```text
Title: <imperative, specific title>
Type: Feature | Bug | Refactor | Chore | Docs
Why: <the open point from the conversation, with context>
Scope: <what is in this slice>
Affected areas: <exact paths or systems>
Acceptance criteria: <concrete, verifiable outcomes>
Out of scope: <what is deliberately not in this slice>
Depends on: <other proposed cards, existing Trello cards, or "None">
Open questions: <must be empty — resolve with the user first>
```

Ask for approval. Do not create any Trello card before the user approves the
plan. If the user changes, merges, splits, or rejects items, revise the plan and
present it again.

### 6. Create the Trello cards

Target: board **"AI Tasks"**, list **"Home Party"**.

Resolve the board and list by name at run time. Known references:

- Board: "AI Tasks" — `https://trello.com/b/HtlaMcA2`
  (id `6a7d754a78e03fab7625f9bf`)
- List: "Home Party" (id `6ad8bb7592105eb673ff02ab`)

Steps:

1. Call `trello_list_boards` and pick the board named exactly "AI Tasks". Do not
   use a similarly named board.
2. Call `trello_get_lists` with that board id and pick the list named exactly
   "Home Party".
3. Call `trello_get_cards_by_list_id` and check for duplicates. Skip any slice
   already covered by an existing card.
4. If the plan has more than one card, call `trello_add_cards_to_list` with the
   cards in dependency order so the list order matches the intended sequence.
5. Apply the matching board label when it exists (`Feature`, `Bug`, `Refactor`
   — resolve ids with `trello_get_board_labels`). Omit the label when no board
   label matches.
6. Report each created card: title, Trello URL, and the slice it represents.

### 7. Card description format

Each card must stand alone. Use this structure:

```markdown
## Context

Why this task exists. Reference the conversation and the relevant docs/specs
(e.g. `docs/GDD.md#scoring`, `docs/adr/*.md`).

## Goal

The observable outcome this slice delivers, in one or two sentences.

## What to do

Detailed, ordered steps covering:

- New/changed scenes, scripts, resources, or components
- Behaviour in the normal case
- Edge cases and error handling
- Integration points (signals, network messages, shared state)

Be specific: name exact file paths, classes, signals, and functions where known.
Do not write implementation code.

## Acceptance criteria

- [ ] Concrete, testable outcome
- [ ] Concrete, testable outcome

Each criterion must be verifiable by the tester agent in the running game.

## Out of scope (optional)

Work deliberately excluded from this slice, so the implementer does not expand
it.


## Depends on (optional)

Other Trello cards or "None — can start immediately."

## Open questions (optional)

Only present when the user explicitly approved an investigation task. Otherwise
this section is omitted. Never leave implementation questions unresolved here.
```

---

## Rules

- **Never assume.** If a requirement, scope, owner, or acceptance criterion is
  unclear or ambiguous, ask the user and wait. An unchecked assumption in a card
  becomes wrong code later.
- **Do not create cards before approval.** Present the plan first.
- **Do not write implementation code.** No GDScript, TSCN, Svelte, or
  TypeScript. Refer to existing files, classes, and signals by name.
- **Do not modify documentation or source files.** This command only produces
  Trello cards.
- **One card per vertical slice.** Do not bundle unrelated outcomes and do not
  split work into horizontal layers.
- **No duplicate cards.** Check the list before creating, including cards that
  are already in "Doing" or "Planning".
- **Do not create cards for completed work.** Verify against the code and the
  conversation before proposing.
- **Use project terminology.** Exact paths, mini-game names, system names, and
  signal names — not vague descriptions.
- **Record dependencies.** If a slice cannot start until another lands, say so
  in the card.
- **Keep each card implementable in one session.** If a slice is too large for
  that, split it further.
