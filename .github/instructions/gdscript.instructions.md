---
description: "Use when writing or editing GDScript (.gd files) in this project. Covers BaseGame API, player input wiring, GameClient signals, and project-specific patterns."
applyTo: "**/*.gd"
---
# GDScript Conventions — Home Party

## BaseGame: required API

All mini-games extend `BaseGame` and must implement:

```gdscript
extends BaseGame

func start_game(players: Array[GameClient], game_setup: GameSetup) -> void:
    # Called once when the game session starts.
    # Wire up player inputs here. Do not call super().
    pass
```

Emit these signals (inherited) to communicate with the game host:

```gdscript
game_finished.emit()    # Game is over
game_restart.emit()     # Replay the same game
back_to_menu.emit()     # Return to game selection screen
```

## Player Input Wiring

Connect `GameClient.input_received` in `start_game`. The signal fires for every packet:

```gdscript
func start_game(players: Array[GameClient], _game_setup: GameSetup) -> void:
    for player in players:
        player.input_received.connect(func(input: String, value): _on_input(player, input, value))

func _on_input(player: GameClient, input: String, value) -> void:
    match input:
        "move":
            # value is Vector2, normalized -1..1 on each axis
            player_node.velocity = value * speed
        "action":
            # value is bool (true = pressed, false = released)
            if value:
                player_node.do_action()
```

Poll the last move vector without a signal (useful in `_process`):

```gdscript
var dir: Vector2 = player.get_move()
```

## Input Layout

Tell the web client which UI to show (call from `start_game`):

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

## Score tracking pattern

```gdscript
var scores: Dictionary = {}   # uuid -> int

func start_game(players: Array[GameClient], _setup: GameSetup) -> void:
    for p in players:
        scores[p.uuid] = 0
```

## Pausing

Games run under `PROCESS_MODE_PAUSABLE` (set by `Game` when launching). Use `get_tree().paused = true/false` to freeze gameplay while showing results UI.
