---
name: setup-minigame
description: Scaffold the base files for a new mini-game that inherits from the shared main/base_scene.tscn.
---

# Setup Mini-Game

Scaffold the full base file structure for a new mini-game inside
`mods-unpacked/KumaGee-VRCore/`. The game scene inherits from the shared
[`main/base_scene.tscn`](../../main/base_scene.tscn).

## Process

### 1. Extract game info

Determine the game name from the conversation context (user says
"set up Hot Potato" → game name is "Hot Potato").

Compute all naming variants and store them for later steps:

| Variant | Example ("Hot Potato") | Where used |
|---|---|---|
| `GAME_NAME` | `HOT_POTATO` | GDD filename, logger tag |
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

### 3. Create the JoinedPlayer script

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.gd`
with this content (fill in `<...>` placeholders):

```gdscript
class_name <GameName>PlayerUI
extends JoinedPlayer


func _ready() -> void:
	super()
	# TODO: Send the appropriate layout for this game's mobile UI
	# LobbyServer.send_layout("<game_name>")
	# TODO: Connect game-specific callbacks (word submit, guess input, etc.)
```

### 4. Create the JoinedPlayer scene

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.tscn`
with this content (fill in `<...>` placeholders):

```
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://main/ui/joined_player.tscn" id="1_base"]
[ext_resource type="Script" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.gd" id="2_script"]

[node name="<GameName>PlayerUI" instance=ExtResource("1_base")]
script = ExtResource("2_script")
```

This produces a scene that inherits from `JoinedPlayer` and attaches the
game-specific script. The `node_paths` from `joined_player.tscn` are inherited
automatically.

### 5. Create the main game script

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.gd` with this
content (fill in `<...>` placeholders):

```gdscript
class_name <GameName>
extends BaseGame

var logger := KumaLog.new("<GAME_NAME>")

func _ready() -> void:
	super()
	prepare_phase.connect(_on_prepare_phase)
	game_phase.connect(_on_game_phase)

func _on_prepare_phase() -> void:
	pass

func _on_game_phase() -> void:
	pass

```

### 6. Create the main game scene

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.tscn` with this
content (fill in `<...>` placeholders):

```
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://main/base_scene.tscn" id="1_base"]
[ext_resource type="Script" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.gd" id="2_game"]
[ext_resource type="PackedScene" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.tscn" id="3_plui"]

[node name="<GameName>" instance=ExtResource("1_base")]
script = ExtResource("2_game")
```

### 7. Create a placeholder 3D icon scene

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_icon.tscn`
with this content:

```
[gd_scene format=3]

[sub_resource type="BoxMesh" id="BoxMesh_icon"]
size = Vector3(0.5, 0.5, 0.2)

[node name="<GameName>Icon" type="Node3D"]

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_icon")
```

The developer replaces this placeholder box with the actual game icon later.

### 8. Scaffold the GameResource `.tres`

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

### 9. Update `docs/GDD.md`

If a `docs/<GAME_NAME>.md` file exists, read `docs/GDD.md` and add the new
game to the `## Games` list if it's not already there:

```markdown
- [<Game Name>](./<GAME_NAME>.md)
```

### 10. Verify

After creating all files, verify the file count and names:

```
mods-unpacked/KumaGee-VRCore/<game-name>/
├── <game_name>.tres
├── <game_name>.gd
├── <game_name>.tscn
├── <game_name>_player_ui.gd
├── <game_name>_player_ui.tscn
└── <game_name>_icon.tscn
```

Use `bash ls` to confirm all 6 files exist.
```