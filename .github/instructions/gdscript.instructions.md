---
description: "Use when writing or editing GDScript (.gd files) in this project. Covers BaseGame API, player input wiring, GameClient signals, and project-specific patterns."
applyTo: "**/*.gd"
---
# GDScript Conventions — Home Party

## XRToolsSceneBase: required API

All mini-games extend `XRToolsSceneBase` which provides APIs for managing the scene
and transitions. The scenes for the `GameClient` must be setup in in the `scene_loaded`
method.

## GameClient: Player Inputs

Use the `GameClient.input_received` to get the player inputs which are one for movement
and two more buttons for the primary and secondary actions. 

The `get_move` can be used to get the current player movement input

## Input Layout

Tell the web client which UI to show:

```gdscript
LobbyServer.send_layout("joystick")   # Analog stick
LobbyServer.send_layout("buttons")    # 4 directional buttons
```

## Logging

Use `KumaLog` instead of `print`:

```gdscript
var logger = KumaLog.new("MyGame")
logger.info("Game started with %d players" % players.size())
logger.debug("Player moved: %s" % str(dir))
```

## Pausing

Games run under `PROCESS_MODE_PAUSABLE` (set by `Game` when launching). Use `get_tree().paused = true/false` to freeze gameplay while showing results UI.
