---
description: "Scaffold a new VR mini-game in KumaGee-VRCore: creates the .gd script, .tscn scene placeholder, and .tres GameResource."
argument-hint: "Name of the new game (e.g. 'balloon_pop')"
agent: "agent"
---
Scaffold a new VR mini-game called **${input:gameName}** inside `mods-unpacked/KumaGee-VRCore/`.

## Steps

1. **Create the game folder**: `mods-unpacked/KumaGee-VRCore/${input:gameName}/`

2. **Create the game script** at `mods-unpacked/KumaGee-VRCore/${input:gameName}/${input:gameName}.gd`:

   - `extends BaseGame`
   - `start_game(players, game_setup)` — call `LobbyServer.send_layout("joystick")`, iterate players, connect `input_received` to a local handler, start a `Timer` node named `PlayTime`
   - `get_points()` — return `scores` dict mapping `player.uuid` to int
   - Private `_on_input(player, input, value)` handler with a `match input:` block covering at minimum `"move"`
   - `_on_game_finished()` that emits `game_finished`
   - Log with `KumaLog.new("${input:gameName}")`

   Use `mods-unpacked/KumaGee-VRCore/whack-a-mole/whack_a_mole.gd` as a structural reference.

3. **Create the scene stub** at `mods-unpacked/KumaGee-VRCore/${input:gameName}/${input:gameName}.tscn`:

   Minimal scene file with a root `Node3D` that has the game script attached and a `Timer` child named `PlayTime` (one-shot, wait_time=60).

   Use this template:
   ```
   [gd_scene load_steps=2 format=3]

   [ext_resource type="Script" path="res://mods-unpacked/KumaGee-VRCore/${input:gameName}/${input:gameName}.gd" id="1_script"]

   [node name="${input:gameName}" type="Node3D"]
   script = ExtResource("1_script")

   [node name="PlayTime" type="Timer" parent="."]
   wait_time = 60.0
   one_shot = true
   ```

4. **Create the GameResource** at `mods-unpacked/KumaGee-VRCore/${input:gameName}/${input:gameName}.tres`:

   ```
   [gd_resource type="Resource" script_class="GameResource" format=3]

   [ext_resource type="Script" path="res://main/game_resource.gd" id="1_gr"]
   [ext_resource type="PackedScene" path="res://mods-unpacked/KumaGee-VRCore/${input:gameName}/${input:gameName}.tscn" id="2_scene"]

   [resource]
   script = ExtResource("1_gr")
   name = "${input:gameName}"
   description = ""
   scene = ExtResource("2_scene")
   ```

## Constraints

- Do not touch `mods-unpacked/KumaGee-Core/` — it is legacy code.
- Do not modify files in `addons/` unless there is a critical bug.
- Follow the `BaseGame` API exactly: `start_game` / `get_points` / signals `game_finished`, `game_restart`, `back_to_menu`.
- The `.tres` must be a `GameResource` so `GameLoader` can discover it automatically — no manual registration needed.
