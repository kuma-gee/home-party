# 008 — Draw & Guess: Mobile Player Pets

Reference: `docs/DRAW_AND_GUESS.md` — Mobile Players section (Player Pets 3D Representation)

## Summary

Draw & Guess currently represents mobile players only as 2D UI elements (`DrawPlayerUI`). This task adds a **3D cube-pet plushie** for each mobile player inside the drawing room, reusing the existing `plushie.tscn` system. Pets sit in front of the desktop viewport and react visually when their player guesses correctly or incorrectly. The VR player can grab and squeak them.

## What to build

### 1. Plushie class name registration

The existing `main/plushie.gd` script has no `class_name`. Add `class_name Plushie` so that other scripts can extend it and the type is available globally.

### 2. Draw Guess Pet script and scene

Create a new script and scene that extend the plushie system with Draw & Guess-specific reaction icons.

**`mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_guess_pet.gd`** — Extends `Plushie` with:
- `@onready var correct_icon: Label3D` — green checkmark ("✓") Label3D, initially hidden
- `@onready var incorrect_icon: Label3D` — red X ("✗") Label3D, initially hidden
- `func on_correct_guess() -> void`:
  - Show `correct_icon`
  - Call `_squeak_and_glow()` (inherited from Plushie — plays squeak, squishes model, pulses player-color glow)
  - After 1.5 seconds, hide `correct_icon`
- `func on_incorrect_guess() -> void`:
  - Show `incorrect_icon`
  - After 0.8 seconds, hide `incorrect_icon`
- `func reset_for_round() -> void`:
  - Hide both `correct_icon` and `incorrect_icon`

**`mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_guess_pet.tscn`** — Inherits from `main/plushie.tscn`:
- Adds two `Label3D` nodes as children of the root:
  - `CorrectIcon` — text "✓", green color, billboard enabled, pixel_size=0.02, positioned at (0, 0.35, 0) (above the pet), initially hidden
  - `IncorrectIcon` — text "✗", red color, billboard enabled, pixel_size=0.02, positioned at (0, 0.35, 0) (same spot), initially hidden
- Script set to `draw_guess_pet.gd`

### 3. Pet spawner script

**`mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_guess_pet_spawner.gd`** — Manages pet lifecycle:
- `@export var pet_scene: PackedScene` — set to `draw_guess_pet.tscn`
- `@export var spawn_points: Node3D` — group node containing Marker3D spawn points
- `var _pets: Dictionary[String, DrawGuessPet]` — uuid → pet mapping
- `func _ready()`:
  - Connect `player_list.player_created` to `_on_player_created`
  - Connect `player_list.player_removed` to `_on_player_removed`
- `func _on_player_created(uuid: String)`:
  - Find an available spawn point (round-robin through children of `spawn_points`)
  - Instantiate `pet_scene`
  - Set position to spawn point global position
  - Set random Y rotation
  - Add as a child of the scene (or use `Staging.add_scene_child()`)
  - Look up player index via `PlayerManager.get_player_idx(uuid)`
  - Look up player color via `PlayerList.get_color(idx)`
  - Look up controller via `PlayerManager.find_player_by_uuid(uuid)`
  - Call `pet.setup(idx, uuid, color, controller)`
  - Store in `_pets[uuid]`
  - Store the pet reference for later reaction calls
- `func _on_player_removed(uuid: String)`:
  - If pet exists in `_pets`, `queue_free()` it and remove from dictionary
- `func get_pet(uuid: String)` — returns the pet node for a given uuid (used by the main game script to trigger reactions)

### 4. Scene modifications

**`mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tscn`**:
- Add a `Marker3D` node group `PetSpawnPoints` as a child of `BaseSceneContent` (sibling of `draw_room`), positioned in front of the desktop viewport area:
  - Add 8 `Marker3D` children named `PetSpawn0` through `PetSpawn7` arranged in a row
  - Positions should be on the floor (y≈0), spaced ~0.5 units apart, facing the drawing area
  - The row should be positioned so all pets are visible in the desktop camera frame
- Add a `DrawGuessPetSpawner` node (type `draw_guess_pet_spawner.gd`) as a child of the root:
  - `pet_scene` → `draw_guess_pet.tscn`
  - `spawn_points` → `../BaseSceneContent/PetSpawnPoints`
  - `player_list` → `%PlayerList`
  - (Other connections handled in `_ready()` via the exported variables)

### 5. Game script modifications

**`mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.gd`**:
- Add `@onready var pet_spawner: DrawGuessPetSpawner = %PetSpawner` (or via direct node reference)
- In `_on_player_guessed()`:
  - On **correct** guess (line 88-91): After `player_ui.mark_guessed_correctly()`, call `pet_spawner.get_pet(player_ui.uuid).on_correct_guess()` if pet exists
  - On **incorrect** guess (line 92-95): After `player_ui.mark_guessed_incorrectly()`, call `pet_spawner.get_pet(player_ui.uuid).on_incorrect_guess()` if pet exists
- In `_start_next_round()` (line 131-133): After iterating DrawPlayerUI children and calling `reset_for_round()`, also iterate pets and call `reset_for_round()` on each

## Files touched

| File | Action | Description |
|------|--------|-------------|
| `main/plushie.gd` | Modified | Add `class_name Plushie` to allow extending |
| `mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_guess_pet.gd` | **New** | Pet script extending Plushie with correct/incorrect reaction icons |
| `mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_guess_pet.tscn` | **New** | Scene inheriting plushie.tscn with CorrectIcon and IncorrectIcon Label3D nodes |
| `mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_guess_pet_spawner.gd` | **New** | Spawner managing pet lifecycle (create on player join, remove on leave) |
| `mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tscn` | Modified | Add PetSpawnPoints (Marker3D row) and DrawGuessPetSpawner node |
| `mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.gd` | Modified | Wire pet reactions into guess handling and round reset |
| `docs/DRAW_AND_GUESS.md` | Modified | Added "Player Pets (3D Representation)" subsection under Mobile Players |

## Data flow

```
Player joins (WebRTC)
  → PlayerManager creates ClientController
  → PlayerList._refresh_list() creates DrawPlayerUI (as before)
  → PlayerList emits player_created(uuid)
     → DrawGuessPetSpawner._on_player_created(uuid)
       → Instantiates DrawGuessPet
       → Calls pet.setup(idx, uuid, color, controller)
       → Positions at spawn point
       → Stores in _pets[uuid]

Player guesses on phone
  → DrawPlayerUI._on_input_received() emits guessed(word)
  → draw_and_guess.gd._on_player_guessed()
    → round_manager.player_guessed() → returns true/false
    → On correct:
        → player_ui.mark_guessed_correctly()         [UI checkmark]
        → pet_spawner.get_pet(uuid).on_correct_guess()  [3D pet celebration]
    → On incorrect:
        → player_ui.mark_guessed_incorrectly()         [UI errormark]
        → pet_spawner.get_pet(uuid).on_incorrect_guess() [3D pet X icon]

Round reset (_start_next_round)
  → for each DrawPlayerUI: child.reset_for_round()
  → for each DrawGuessPet: pet.reset_for_round()    [hides icons]

Player disconnects
  → PlayerList emits player_removed(uuid)
    → DrawGuessPetSpawner._on_player_removed(uuid)
      → pet.queue_free()
      → Removes from _pets dict
```

## New signals / functions / classes

### New classes
- `DrawGuessPet` (extends `Plushie`) — registered via `class_name` or via the scene script

### New functions on `DrawGuessPet`
| Function | Description |
|----------|-------------|
| `on_correct_guess()` | Show checkmark icon + glow + squish squeak, auto-hide after 1.5s |
| `on_incorrect_guess()` | Show X icon, auto-hide after 0.8s |
| `reset_for_round()` | Hide both icons |

### New functions on `DrawGuessPetSpawner`
| Function | Description |
|----------|-------------|
| `get_pet(uuid: String) -> DrawGuessPet` | Return the pet node for a given uuid |
| (internal) `_on_player_created(uuid)` | Spawn pet at next spawn point |
| (internal) `_on_player_removed(uuid)` | Remove and free pet |

## Migration / compatibility

None — no breaking changes. The lobby plushies remain unaffected. Adding `class_name Plushie` to `plushie.gd` is a purely additive change with no side effects.

## Acceptance criteria

- [ ] Each mobile player who joins the game gets a 3D cube-pet plushie spawned in a row in front of the desktop viewport
- [ ] Pets show the correct animal for each player (cycling through the 15 animal models)
- [ ] Pets are colored with the player's assigned color (glow material)
- [ ] When a player guesses correctly, their pet plays a squeak sound, squishes, glows, and a green "✓" icon appears above its head for 1.5s
- [ ] When a player guesses incorrectly, a red "✗" icon appears above their pet's head for 0.8s
- [ ] When a new round starts, all pets reset (icons hidden)
- [ ] When a player disconnects, their pet is removed from the scene
- [ ] The VR player can grab, move, and squeak pets (same as lobby plushies)
- [ ] Pets are visible on the shared desktop TV screen
- [ ] Pets do not obstruct the drawing area or the desktop viewport
- [ ] Pets work correctly with 1–8 mobile players (spawning at available spawn points)

## Blocked by

None — can start immediately. The existing plushie system, DrawPlayerUI, and round manager are all in place.
