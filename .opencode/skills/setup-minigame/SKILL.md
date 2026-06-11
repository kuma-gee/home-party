---
name: setup-minigame
description: Scaffold the base files for a new mini-game.
---

# Setup Mini-Game

Scaffold the full base file structure for a new mini-game inside `mods-unpacked/KumaGee-VRCore/`.

## Process

### 1. Extract game info

Determine the game name from the conversation context (user says
"set up Hot Potato" → game name is "Hot Potato").

Compute all naming variants and store them for later steps:

| Variant | Example ("Hot Potato") | Where used |
|---|---|---|
| `GAME_NAME` | `HOT_POTATO` | GDD filename, .tres name field |
| `Game Name` | `Hot Potato` | Display name in the .tres |
| `game-name` | `hot-potato` | Folder name under mods-unpacked/ |
| `game_name` | `hot_potato` | File prefix (.tres, .tscn, .gd) |
| `GameName` | `HotPotato` | GDScript class names |

If the user hasn't provided a game name, ask for it.

Look for the GDD at `docs/<GAME_NAME>.md`. If it exists, read it and extract:
- The **description** (first paragraph after the title)
- **min_recommended_players** and **max_recommended_players** (from lines like
  `- **Recommended Players:** 4+`)

If the GDD doesn't exist yet, use placeholders and note it in the summary.

### 2. Create directory

Create:
```
mods-unpacked/KumaGee-VRCore/<game-name>/
```

Use `bash` to run `mkdir -p`.

### 3. Scaffold the GameResource `.tres`

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.tres` with this
content (fill in `<...>` placeholders):

```
[gd_resource type="Resource" script_class="GameResource" format=3]

[ext_resource type="Script" path="res://main/game_resource.gd" id="1_script"]
[ext_resource type="PackedScene" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.tscn" id="2_scene"]
[ext_resource type="PackedScene" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_icon.tscn" id="3_icon"]

[resource]
script = ExtResource("1_script")
name = "<Game Name>"
description = "<Insert description from GDD, or a placeholder>"
scene = ExtResource("2_scene")
icon = ExtResource("3_icon")
min_recommended_players = 2
```

If the GDD specified a different `min_recommended_players`, use that value.
If the GDD specified `max_recommended_players`, add that line too.

### 4. Create the main game script

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.gd`:

```gdscript
extends XRToolsSceneBase
```

### 5. Create the main game scene

Use `godot_create_scene` with root type `Node3D` at path
`mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.tscn`.

Then use `godot_add_node` to build the node tree:

| Parent path | Node type | Node name | Properties |
|---|---|---|---|
| root | WorldEnvironment | WorldEnvironment | — |
| root | DirectionalLight3D | DirectionalLight3D | — |
| root | Camera3D | Camera3D | — |
| root | XRToolsPlayerBody (instance `res://main/vr/vr_space.tscn`) | XRPlayer | — |
| root | CanvasLayer | CanvasLayer | — |
| CanvasLayer | MarginContainer | MarginContainer | — |
| MarginContainer | PlayerList (script `res://main/ui/player_list.gd`) | PlayerList | player_scene = `res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.tscn` |
| root | Timer | GameTimer | wait_time = 180, one_shot = true |

After creating nodes, use `godot_add_node` to add the script as a resource to
the root node (set `script = ExtResource` pointing to the `.gd` file).

Set the following **@export** node path annotations on the root scene by
setting the corresponding properties on the root node:

```gdscript
player_list = NodePath("CanvasLayer/MarginContainer/PlayerList")
xr_player = NodePath("XRPlayer")
```

Use `godot_save_scene` to persist the result.

### 6. Create the JoinedPlayer script

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.gd`:

```gdscript
class_name <GameName>PlayerUI
extends JoinedPlayer


func _ready() -> void:
	super()
```

### 7. Create the JoinedPlayer scene

Use `godot_create_scene` to create a scene inheriting from
`res://main/ui/joined_player.tscn` at path
`mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.tscn`.

Then use `godot_add_node` to attach the script from step 6 to the root node.

### 10. Create a placeholder 3D icon scene

Use `godot_create_scene` with root type `Node3D` at path
`mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_icon.tscn`.

Add a `MeshInstance3D` child with a `BoxMesh` as the mesh (simple placeholder
the developer replaces later).

### 11. Update `docs/GDD.md`

If a `docs/GAME_NAME.md` file exists, read `docs/GDD.md` and add the new game
to the `## Games` list if it's not already there:

```markdown
- [<Game Name>](./<GAME_NAME>.md)
```