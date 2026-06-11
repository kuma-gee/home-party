---
name: clear-issues
description: Clean up finished tasks
---

# Clear Issues (Delete Finished Tasks)

## Process

### 1. Scan task files

List all `.md` files in `docs/tasks/`.

### 2. Check each file

For each file, parse the content to find all acceptance criteria lines. An AC line matches the pattern `- [ ]` or `- [x]` anywhere in the file.

- If every AC line is `- [x]` (checked), the task is **finished**.
- If a task is finished and all tasks referencing it in the "Blocked By" section is finished too, then it's safe to delete
- If any AC line is `- [ ]` (unchecked), the task is **not finished** — skip it.
- If the file has no AC lines at all, skip it (no criteria to judge by).

### 3. Delete finished files

For each finished file, use the Bash tool to delete it (`rm docs/tasks/<filename>`).
If every referenced task is also finished

### 4. Report

Print a summary of:
- Which files were deleted
- Which files were skipped (and why: unfinished or no ACs)
- Total counts

