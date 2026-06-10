---
name: clear-issues
description: Delete all markdown task files in gdd/tasks/ where every acceptance criterion is checked (`- [x]`), i.e., the task is fully finished.
---

# Clear Issues (Delete Finished Tasks)

## Process

### 1. Scan task files

List all `.md` files in `gdd/tasks/`.

### 2. Check each file

For each file, parse the content to find all acceptance criteria lines. An AC line matches the pattern `- [ ]` or `- [x]` anywhere in the file.

- If every AC line is `- [x]` (checked), the task is **finished**.
- If any AC line is `- [ ]` (unchecked), the task is **not finished** — skip it.
- If the file has no AC lines at all, skip it (no criteria to judge by).

### 3. Delete finished files

For each finished file, use the Bash tool to delete it (`rm gdd/tasks/<filename>`).

### 4. Report

Print a summary of:
- Which files were deleted
- Which files were skipped (and why: unfinished or no ACs)
- Total counts

