---
name: setup-minigame
description: Scaffold the base files for a new mini-game following the standard defined in docs/BASE_SCENE.md.
---

# Setup Mini-Game

Scaffold the full base file structure for a new mini-game inside
`mods-unpacked/KumaGee-VRCore/`. All files follow the standard defined in
[`docs/BASE_SCENE.md`](../../docs/BASE_SCENE.md). Read that document first if
you haven't already.

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
extends XRToolsSceneBase

signal game_started

@export var player_list: PlayerList
@export var prepare_ui: Control
@export var game_ui: Control
@export var desktop_gameover: DesktopGameover
@export var game_timer: Timer

# Add game-specific @export vars here, e.g.:
# @export var my_tool: MyTool

var logger := KumaLog.new("<GAME_NAME>")


func _ready() -> void:
	# Connect signals that don't depend on game state here
	pass

func _on_game_start() -> void:
	# --- Prepare phase ---
	BGMManager.set_volume_db(-40.0, true)
	prepare_ui.show()
	game_ui.hide()
	game_timer.stop()

	# TODO: Show prepare screen in VR (if needed):
	# xr_player.show_screen(prepare_scene)

	# Listen for ready state changes
	player_list.ready_changed.connect(_check_all_ready)

func _check_all_ready(start := false) -> void:
	# TODO: Add game-specific ready conditions here
	# (word submitted, loadout confirmed, etc.)
	if start and player_list.is_all_ready():
		_start_game()

func _start_game() -> void:
	# --- Transition to gameplay ---
	BGMManager.set_volume_db(-25.0, false)
	PlayerManager.start_game()
	prepare_ui.hide()
	game_ui.show()
	xr_player.hide_screen()
	game_timer.start()
	game_started.emit()
	logger.info("Game started")

func _finish_game(message: String) -> void:
	logger.info("Game over: %s" % message)
	xr_player.gameover(message)
	if desktop_gameover:
		desktop_gameover.show_gameover(message, [])
	game_timer.stop()
```

### 6. Create the main game scene

Create `mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.tscn` with this
content (fill in `<...>` placeholders):

```
[gd_scene format=3]

[ext_resource type="Script" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>.gd" id="1_game"]
[ext_resource type="PackedScene" path="res://main/vr/vr_space.tscn" id="2_vrspace"]
[ext_resource type="Script" path="res://main/ui/player_list.gd" id="3_plist"]
[ext_resource type="PackedScene" path="res://main/ui/desktop_gameover.tscn" id="4_dkgov"]
[ext_resource type="PackedScene" path="res://mods-unpacked/KumaGee-VRCore/<game-name>/<game_name>_player_ui.tscn" id="5_plui"]

[node name="<GameName>" type="Node3D" node_paths=PackedStringArray("player_list", "prepare_ui", "game_ui", "desktop_gameover", "game_timer", "xr_player")]
script = ExtResource("1_game")
player_list = NodePath("CanvasLayer/MarginContainer/PlayerList")
prepare_ui = NodePath("CanvasLayer/PrepareUI")
game_ui = NodePath("CanvasLayer/GameUI")
desktop_gameover = NodePath("CanvasLayer/DesktopGameover")
game_timer = NodePath("GameTimer")
xr_player = NodePath("XRPlayer")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]

[node name="Camera3D" type="Camera3D" parent="."]
cull_mask = 786431
current = true

[node name="XRPlayer" parent="." instance=ExtResource("2_vrspace")]

[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="PrepareUI" type="Control" parent="CanvasLayer"]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="GameUI" type="Control" parent="CanvasLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="MarginContainer" type="MarginContainer" parent="CanvasLayer"]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
grow_horizontal = 0

[node name="PlayerList" type="VBoxContainer" parent="CanvasLayer/MarginContainer"]
layout_mode = 2
script = ExtResource("3_plist")
player_scene = ExtResource("5_plui")

[node name="DesktopGameover" parent="CanvasLayer" instance=ExtResource("4_dkgov")]

[node name="GameTimer" type="Timer" parent="."]
wait_time = 180.0
one_shot = true

[node name="<GameName>Content" type="Node3D" parent="."]
```

Set `wait_time` on `GameTimer` to the game's actual duration (in seconds) if
known from the GDD. The default is 180 (3 minutes).

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