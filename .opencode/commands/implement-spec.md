---
name: implement-spec
description: >-
  Implements a detailed technical specification produced by the create-spec
  skill. Reads the spec from docs/tasks/, parses the Files touched section,
  and applies each change in dependency order.
---

# Implement Specification

Implements a change specification created by the `create-spec` skill.
The spec must be stored in `docs/tasks/<TASK_NAME>.md` and follow the format
defined in step 5 of the create-spec skill (Summary, Files touched,
Data flow, New signals/functions/classes, Migration/compatibility).

## Usage

```
implement-spec <file>
```

Where `<file>` is a path relative to `docs/tasks/` (e.g., `007-new-mechanic.md`).

If no file is provided, use the most recently modified `.md` file in `docs/tasks/`
that is not referenced as a blocker by any other task.

## Process

### 1. Read the specification

Read the specified file from `docs/tasks/`. If none was provided, find the most
recently modified task file that is not blocked by unfinished tasks.

Identify these sections in the document:
- **Summary** — what the change is and why
- **Files touched** — every file to create or modify, with a one-line description
- **Data flow** — signals, function calls, network messages
- **New signals / functions / classes** — API surface of any added code
- **Migration / compatibility** — breaking changes, saved data, network protocol

If any of these sections are missing or unclear, stop and report.

### 2. Plan the implementation

From the **Files touched** section, build an ordered change list:

1. **Create** any new files first (directories implied by paths)
2. **Modify** existing files after their new dependencies exist
3. **Remove** any files marked for deletion last

For each file, note:
- The **type** of change: create / modify / remove
- The **description** from the spec ("one-line description of the change")
- Any **detailed requirements** from the Data flow, New API, or Migration sections

### 3. Review existing code

Before making changes, read the current state of every existing file listed in
"Files touched". Understand the current structure, signals, and patterns so
changes fit the existing architecture.

For new files, read similar existing files in the same directory to match
conventions (e.g., if creating a new mini-game scene, read an existing one).

### 4. Apply changes

Work through the ordered change list one file at a time:

- **Creating a file:** Write the file matching the spec's description. Follow
  existing patterns in the same directory. If the spec is ambiguous, prefer the
  simplest implementation that satisfies the spec.
- **Modifying a file:** Apply only the changes described in the spec. Do not
  refactor unrelated code. Reference the spec's Data flow and New API sections
  for exact signal names, function signatures, and class structures.
- **Removing a file:** Delete the file. Check for references in other files and
  report any broken references found.

After each change, re-read the spec section for that file to confirm alignment.

### 5. Verify the implementation

After all changes are applied:

1. Load the `verify-feature` skill and delegate verification to the tester
   subagent. The tester should confirm each item in the spec's Summary and
   Data flow works end-to-end.

2. If any issues are found, fix them and re-verify.

### 6. Summarize

Report the results to the developer agent:

- **Spec implemented:** path to the spec file
- **Files created:** list
- **Files modified:** list
- **Files removed:** list
- **Verification result:** pass / fail with details
- **Open issues:** anything left incomplete, ambiguous, or untested

## Rules

- **Do not implement features not in the spec.** Every change must trace back
  to a line in the spec's "Files touched" section.
- **Do not refactor unrelated code.** If you find issues outside the spec's
  scope, note them in the summary but do not fix them.
- **Prefer small, reversible changes.** If a change is risky, prefer creating
  a new file and redirecting references over in-place mutation.
- **Stop and report** if the spec is contradictory, refers to missing systems,
  or cannot be followed as written.
