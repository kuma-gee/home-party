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

## Placing Players in a VR Game

The VR player is added to the scene via `vr_space.tscn` and player functionality like
pickup or pointer is added to the hands inside the game scene.

While mobile players connecting via `GameClient` will have a script that handles the
input from the `GameClient` and act accordingly.

## Game Resource Registration

Every VR game needs a `.tres` file so `GameLoader` can discover it:

```gdscript
# In the Godot editor: create a new GameResource resource, fill fields, save as <game>.tres
# Fields: name (String), description (String), scene (PackedScene), image (Texture2D), tags (Array[String])
```
