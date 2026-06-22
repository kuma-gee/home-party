---
name: add-mcp-function
description: Add a new MCP tool/command to the Godot MCP bridge for testing purposes. When functionality is needed for writing tests or directly testing through agents
---

# Add MCP Function

When the AI identifies a need for a new MCP tool to assist with testing or debugging, follow the process below. **Always ask the user for approval before writing any code.**

## Architecture

MCP functions span two files that must be kept in sync:

| Layer | File | What to add |
|---|---|---|
| **Godot bridge** | `main/utils/godot_mcp_bridge.gd` | A new `match` arm in `handle_request()` + a new function that does the work |
| **Python client** | `.opencode/mcp/godot-debug.py` | A new `@mcp.tool()` function that calls the Godot bridge via `_godot_request()` |

## Process

### 1. Identify the need

When testing reveals the AI needs a capability the current MCP tools don't provide (e.g., a new inspection method, a mutation of game state, a signal watcher, etc.), note what the function should do.

### 2. Propose to the user

Present a clear proposal using `question` tool:

```
I need to add an MCP function to <purpose>. The function would:

<what the function does>
<what it returns>

I'll add it to:
- main/utils/godot_mcp_bridge.gd — the Godot-side command handler
- .opencode/mcp/godot-debug.py — the Python MCP tool wrapper

Shall I proceed?
```

**Wait for explicit approval before writing any code.**

### 3. Implement

Once approved, make changes to both files in parallel:

#### `main/utils/godot_mcp_bridge.gd`

1. Add a new `match` arm:
   ```gdscript
   "<command_name>":
       return <function_name>(payload.get("arg1", default), ...)
   ```

2. Add the implementation function following existing conventions — return a `Dictionary` with either the result or an `"error"` key.

3. If storing server-side state, add a new member variable in the top `var` block.

#### `.opencode/mcp/godot-debug.py`

1. Add a new `@mcp.tool()` function with:
   - A descriptive docstring (becomes the tool description for the AI)
   - Type-annotated parameters
   - A call to `_godot_request("<command_name>", {...})`

2. Example:
   ```python
   @mcp.tool()
   def my_new_tool(param1: str, param2: int = 42) -> dict:
       """Description of what this tool does."""
       return _godot_request("my_new_tool", {"param1": param1, "param2": param2})
   ```

### 4. Conventions

- **Command names**: use `snake_case` matching the Godot-side command string
- **Python tool names**: use `snake_case` matching the `@mcp.tool()` function name
- **Error handling**: Godot returns `{"error": "..."}` on failure; the Python side doesn't need extra error handling since `_godot_request()` already wraps transport errors
- **Server-side state**: if the function stores info for later use, expire it or let the user clear it explicitly
- **Properties**: serialize Godot `Vector2`, `Vector3`, `Transform3D` etc. as plain arrays/dicts for JSON transport

## Emacs philosophy reminder

Each new MCP command should be **simple**, **focused**, and **composable** — do one thing well so it can be combined with other tools for sophisticated testing workflows.
