---
name: write-adr
description: >-
  Write an Architecture Decision Record (ADR) to `docs/adr/` documenting important architectural or design
  decisions. Use when the user says "write an ADR for...", "record a decision about...",
  or "document why we chose...".
---

# Write ADR (Architecture Decision Record)

Write a lightweight ADR to `docs/adr/` using the Michael Nygard format extended
with Date and Alternatives Considered.

## Process

### 1. Ensure the ADR directory exists

Check if `docs/adr/` exists. If not, create it:

```bash
mkdir -p docs/adr/
```

### 2. Determine the next ADR number

List all files matching `docs/adr/ADR-*.md` (case-sensitive). Parse the 4-digit
number (`NNNN`) from each filename (`ADR-NNNN-*.md`). Find the highest number
and increment by 1. Pad to 4 digits with leading zeros (e.g., `0001`, `0002`).

If no ADRs exist yet, start at `0001`.

### 3. Gather context from the user

Ask the user (or extract from conversation) the following pieces. Present them
as a clear recap so the user can confirm or correct:

| Field | Guidance |
|---|---|
| **Title** | Short phrase (< 10 words), e.g. "Use Godot 4.4 with .NET disabled" |
| **Status** | One of: `Proposed`, `Accepted`, `Deprecated`, `Superseded`. Default to `Proposed` if not specified. |
| **Context** | What forces, constraints, technical or design problems led to this decision? (2–4 sentences) |
| **Decision** | What was decided? Concrete and unambiguous. (1–3 sentences) |
| **Consequences** | What trade-offs does this introduce? List both positive outcomes and negative side-effects (technical debt, performance impact, maintenance cost, etc.). |
| **Alternatives Considered** | What other options were evaluated and why were they rejected? One bullet per alternative. |

If the user provides a high-level description without explicitly separating
these fields, ask confirming questions to extract each piece cleanly.

> **Important:** This is a conversation with the user — do NOT silently invent
> context or decisions. If the user's description is vague, ask follow-up
> questions before drafting.

### 4. Draft the ADR content

Build the ADR using the template below. Use the date the conversation is
happening (`YYYY-MM-DD` format).

<adr-template>
```markdown
# ADR-NNNN: Title

- **Status:** Proposed | Accepted | Deprecated | Superseded
- **Date:** YYYY-MM-DD

## Context

[Why is this decision needed? What forces, constraints, technical or design
problems are at play?]

## Decision

[What was decided? Be specific and unambiguous. This is the single choice we
made.]

## Consequences

[What trade-offs does this decision introduce? List positive outcomes and
negative side-effects — technical debt, performance impact, maintenance cost, etc.]

## Alternatives Considered

- **Option 1:** [Brief description] — rejected because [reason]
- **Option 2:** [Brief description] — rejected because [reason]
```
</adr-template>

Remove any sections that are genuinely empty (e.g., "Alternatives Considered"
with no entries — but encourage the user to fill it in).

### 5. Present the draft to the user

Show the full ADR markdown to the user and ask for approval.
Iterate on any requested changes before writing to disk.

### 6. Save the ADR file

Once approved, save the file as:

```
docs/adr/ADR-NNNN-title-slug.md
```

where `title-slug` is the title lowercased with spaces replaced by hyphens
(e.g., "Use Godot 4.4 with .NET disabled" → `use-godot-44-with-net-disabled`).
