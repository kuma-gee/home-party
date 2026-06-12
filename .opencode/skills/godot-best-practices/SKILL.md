---
name: godot-best-practices
description: Best practices for Godot 4.6 and GDScript
---

## Formatting and general guidelines

- Double quotes by default. Use single quotes only when it avoids escapes
- Always include leading/trailing zero: `0.234`, `13.0` (never `.234` or `13.`).
- `:=` used where type is obvious; explicit type annotation where ambiguous.

- Signals use past tense: `signal door_opened`, `signal score_changed`
- Signal handlers prefixed with `_on_`: `func _on_door_opened():
- Call signal using `door_opened.emit(args)`, never `emit_signal("door_opened", args)`

- Do not use `@export` with `NodePath`, directly use the node type
- Never use `get_node()`, prefer `@onready var` or `%UniqueName` for node references
- Build scenes by **instancing** sub-scenes, not by creating deep node trees:

## Code Order (top-to-bottom in .gd files)

```
01. @tool, @icon, @abstract, @static_unload
02. class_name
03. extends
04. ## doc comment (class description)
05. signals
06. enums
07. constants
08. static variables
09. @export variables (grouped by @export_category)
10. public variables
11. private variables
12. @onready variables
13. _static_init() / static methods
14. _init()
15. _enter_tree()
16. _ready()
17. _process() / _physics_process()
18. remaining built-in virtual methods
19. public methods
20. private methods
21. inner classes
```

## Naming Conventions

| Type         | Convention       | Example                    |
| ------------ | ---------------- | -------------------------- |
| File names   | `snake_case`     | `player_manager.gd`        |
| Class names  | `PascalCase`     | `PlayerManager`            |
| Node names   | `PascalCase`     | `Camera3D`, `Player`       |
| Functions    | `snake_case`     | `func load_level():`       |
| Variables    | `snake_case`     | `var particle_effect`      |
| Signals      | `snake_case`     | `signal door_opened`       |
| Constants    | `CONSTANT_CASE`  | `const MAX_SPEED = 200`    |
| Enum names   | `PascalCase`     | `enum Element`             |
| Enum members | `CONSTANT_CASE`  | `{EARTH, WATER, AIR}`      |
| Private      | `_underscore`    | `_counter`, `_recalculate` |
