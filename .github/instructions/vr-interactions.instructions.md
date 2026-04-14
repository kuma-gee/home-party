---
description: "Use when working on VR interactions, hand tracking, XR physics, or interactable objects in KumaGee-VRCore. Covers godot-xr-tools patterns, physics layers, and VR-specific node setup."
applyTo: "mods-unpacked/KumaGee-VRCore/**"
---
# VR Interactions — KumaGee-VRCore

## godot-xr-tools (addons/godot-xr-tools/)

Read the addon for API details but never modify it. Key node types:

| Node | Purpose |
|------|---------|
| `XRToolsPickable` | Rigidbody that can be grabbed by hands |
| `XRToolsInteractableAreaButton` | 3D area that acts as a button; emits `button_pressed` |
| `XRToolsFunctionPickup` | Attached to hand controllers; handles grab logic |

Connect to button signals in `_ready`:

```gdscript
@export var my_button: XRToolsInteractableAreaButton

func _ready() -> void:
    my_button.button_pressed.connect(_on_button_pressed)
```

## Physics Layers

| Layer | Name | Meaning |
|-------|------|---------|
| 1 | Static World | Non-moving environment geometry |
| 2 | Dynamic World | Moving physics objects |
| 18 | Player Hands | XR controller / hand colliders |
| 20 | Player Body | Player body collider |
| 21 | Pointable Objects | Objects the hand pointer ray can interact with |
| 23 | UI Objects | 3D UI panels and buttons |

Assign collision layers/masks in the inspector or in script:

```gdscript
collision_layer = (1 << 0)        # Layer 1 (static world)
collision_mask  = (1 << 17) | (1 << 19)  # Responds to hands (18) and body (20)
```

## Hand UI Pattern

Show HUD anchored to the player's palm. Reference: `pirate/hand_ui.gd`.

Key idea — `Sprite3D` (or `SubViewport3D`) is a child of the hand node; toggle `visible` based on palm orientation:

```gdscript
extends Sprite3D

@export var palm_up_threshold := 0.5

func _process(_delta: float) -> void:
    visible = global_basis.x.dot(Vector3.UP) > palm_up_threshold
```

Attach the node as a child of the XR hand controller node so it follows hand movement automatically.

## Placing Players in a VR Game

`start_game` typically assigns each `GameClient` an in-world proxy node rather than spawning a physical avatar:

```gdscript
func start_game(players: Array[GameClient], _setup: GameSetup) -> void:
    LobbyServer.send_layout("joystick")
    for i in range(players.size()):
        var proxy = player_scene.instantiate()
        proxy.game_client = players[i]
        var spawn = spawn_points[i % spawn_points.size()]
        spawn.add_child(proxy)
        proxy.global_transform = spawn.global_transform
```

## Pirate game reference (pirate/)

- `pirate_defend.gd` — template for a single-VR-player game with survival/timer logic
- `player_shoot_point.gd` — player proxy that reads joystick input to aim and fire
- `gun_cast.gd` — raycasting from gun node to determine shoot target

## Whack-a-Mole reference (whack-a-mole/)

- `whack_a_mole.gd` — template for a VR-physical hit game with `XRToolsPickable`
- `player_mole.gd` — player proxy that maps web-client directional input to mole focus index
- `mole.gd` — target object; emits `hit` / `miss` signals

## Game Resource Registration

Every VR game needs a `.tres` file so `GameLoader` can discover it:

```gdscript
# In the Godot editor: create a new GameResource resource, fill fields, save as <game>.tres
# Fields: name (String), description (String), scene (PackedScene), image (Texture2D), tags (Array[String])
```
