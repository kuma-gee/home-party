# Task: Player fall reset to same rotation

Trello card #117 (`6ae7043a486894a2f3a55867`), board `AI Tasks`, list `Home Party`.

## Spec

> When the player falls to the player reset area and gets respawned, the current
> player rotation should stay the same so they don't get disoriented.

## Implementation (changed files)

- `main/vr/vr_space.gd`
  - `signal center_player(offset: Vector3, keep_rotation: bool)`
  - `reset_space(offset = Vector3.ZERO, keep_rotation = false)` emits both args
  - `reset_area.body_entered` now calls `reset_space(Vector3.ZERO, true)` (fall reset keeps rotation)
  - pause-menu "Reset Space" button still calls `reset_space()` → `keep_rotation = false` (full re-center, unchanged)
- `addons/godot-xr-tools/staging/scene_base.gd`
  - `reset_player_space(offset, keep_rotation = false)` forwards the flag
  - `center_player_on(p_transform, keep_rotation = false)`:
    - `keep_rotation = true`: camera local x/z zeroed (as before), origin **only translated** to `p_transform.origin`, rotation untouched; player body moved to `p_transform.origin` keeping its current rotation
    - `keep_rotation = false`: original behavior (`p_transform * camera_yaw.inverse()`), snaps facing to the target transform

## How to verify (Godot MCP bridge, game running in desktop fallback)

> MCP bridge limitation (probe-verified): `call_method` uses `callv` with raw JSON
> values, and Godot cannot convert a JSON array to `Vector3` — `set("global_position",
> [x,y,z])` silently fails and typed `Vector3` params error out. So do NOT call
> `reset_space([0,0,0], true)` or set transforms via `set`. Use the workarounds below.

1. Start a mini-game built on `main/base_scene.tscn` via the `start-minigame` skill
   (e.g. `godot.call_method("/root/Staging/Scene/MenuWorld/GameShelve",
   "select_game_with_path", ["res://mods-unpacked/KumaGee-VRCore/vortex-volley/vortex_volley.tres"])`
   then `start_selected_game`), wait for the game root under `/root/Staging/Scene/`.
2. Locate the rig: `godot.list_nodes_by_type("VRSpace")` → e.g.
   `/root/Staging/Scene/VortexVolley/XRPlayer`. Then:
   - reset_area = `<vrspace>/SubViewport/ResetArea`
   - origin = `<vrspace>/SubViewport/XRPlayer`
   - camera = `<vrspace>/SubViewport/XRPlayer/XRCamera3D`
   - game root (BaseGame, holds `spawn_transform`) = parent scene root
3. Baseline: `godot.get_properties(camera)` → `global_rotation` (yaw = index 1);
   `godot.get_properties(origin)` → `global_position`. Game root
   `get_properties` → `spawn_transform` (12-element array; origin = elements 9..11).
4. Rotate the player with a scalar-arg method:
   `godot.call_method(origin, "rotate_y", [1.5708])`; read yaw again (`yaw_rotated`, must differ).
5. Trigger the fall-reset path exactly as a body entering the area does
   (the handler `func(_b): reset_space(Vector3.ZERO, true)` ignores its argument, so
   emitting the signal is equivalent):
   `godot.call_method(reset_area, "emit_signal", ["body_entered", null])`
6. **PASS (feature):** `get_properties(camera).global_rotation[1]` ≈ `yaw_rotated`
   (rotation preserved) AND `get_properties(origin).global_position` ≈ spawn origin.
7. **Regression A (menu reset):** `godot.call_method(vrspace, "reset_space", [])`
   (defaults → `keep_rotation=false`) → camera yaw snaps to spawn facing (old behavior).
8. **Regression B:** scene load ran `center_player_on(spawn_transform)` with default
   `false` — player starts facing spawn direction.

## Pass criteria

- Step 6 holds (rotation identical after fall reset, position at spawn).
- Steps 7–8 unchanged (spawn-facing snap where `keep_rotation = false`).
