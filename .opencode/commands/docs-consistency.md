---
name: docs-consistency
description: Scan the codebase and documentation for inconsistencies 
---

# Docs Consistency Check

Detect drift between `docs/` and the actual codebase. Each check below produces a list of issues.
Run all checks unless a specific subset is requested.

## Process

### 1. Analyze Documentation

Starting from `docs/GDD.md`. Analyze all the related and linked documentation files to get an
understanding of the current game design.

### 2. Compare with codebase

Check if all the described features and mechanics are implemented in the current codebase.
Compare each of part of the game design one by one, starting with the general design and
menu world. Then going over each of the games.

### 3. Summary Report

After all checks complete, produce a consolidated report on what is missing or is different
from the documentation.

## Reusability

This command can be re-run at any time. Add new checks as new patterns of drift are discovered.
