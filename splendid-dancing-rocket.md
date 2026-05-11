# Plan: Fix Game Transition / Loading Screen

## Context

Scene transitions are broken for *subsequent* loads (menu → game, game → menu). The loading screen appears but is invisible (all black), making it look "stuck". The fade-in after scene load sometimes also fails. Root cause: `VRSpace.deactivate()` adds a second fade layer (key `""`) on top of staging's fade layer (key `"staging"`), and this second layer persists through the entire loading screen phase.

## Root Cause (confirmed from code trace)

`staging.gd` (addons — read-only) runs this sequence:

1. Starts tween `"staging"` 0→1 (fade to black, 0.2s) — **not awaited**
2. Calls `await current_scene.xr_player.deactivate()`
   - `vr_space.gd` starts its own tween `""` 0→1 (0.2s) and awaits it
   - After 0.2s: `"staging"` = 1.0, `""` = 1.0 → screen black ✓
3. Removes old scene
4. Shows loading screen, emits `switching_to_loading_scene`
5. Kills old tween, fades `"staging"` 1→0 to reveal loading screen → awaits
6. After fade: `"staging"` = 0.0, **but `""` = 1.0 still** → **loading screen BLACK** ← bug
7. Progress bar updates internally, user sees nothing; looks "stuck"
8. Eventually: new scene loaded, `activate()` fades `""` 1→0
9. Staging fades `"staging"` 1→0 → scene finally visible

The `""` fade key from `VRSpace.deactivate()` is never cleared during the loading screen phase.

**First load is unaffected** — VRSpace doesn't exist yet when loading screen is shown.

## Fix

**File:** `main/vr/vr_space.gd` (only file to change)

### Changes

1. `deactivate()`: Replace the 0.2s fade tween with a 0.2s timer + immediate `set_fade(0.0)`.  
   - The timer preserves the timing gap (lets staging's background 0→1 tween complete before we proceed).  
   - `set_fade(0.0)` clears the `""` layer so the loading screen is visible.

2. `activate()`: Remove the tween entirely. Immediately clear `""` to 0.0 and set origin/camera current. Staging handles the visual fade-from-black after this returns.

3. Remove `fade_tw` variable (no longer needed).

### New `vr_space.gd`

```gdscript
class_name VRSpace
extends Node

@export var origin: XROrigin3D
@export var camera: XRCamera3D
@export var fade: XRToolsFade

func _ready() -> void:
    set_fade(1.0)

func set_fade(v: float):
    fade.set_fade_level("", Color(0, 0, 0, v))

func deactivate():
    await get_tree().create_timer(0.2).timeout
    set_fade(0.0)

func activate():
    set_fade(0.0)
    origin.current = true
    camera.current = true
```

### Why this works

- `deactivate()`: The 0.2s timer matches the duration of staging's `"staging"` tween (which is started just before `await deactivate()`). After the timer, `""` = 0.0 and `"staging"` = 1.0. Loading screen shows correctly.
- `activate()`: `""` = 0.0 immediately. `origin.current`/`camera.current` set while screen is still black (`"staging"` = 1.0). Staging then fades `"staging"` 1→0 to reveal the scene.
- Transition time improves: reveal goes from 0.4s (two sequential 0.2s tweens) to 0.2s (staging's tween only).

## Files

| File | Action |
|------|--------|
| `main/vr/vr_space.gd` | Rewrite `deactivate()` and `activate()`, remove `fade_tw` |

No other files need changes. `addons/` is untouched.

## Verification

1. Launch game in Godot editor (play scene `main/game.tscn`)
2. Connect 1+ phone players
3. Select a game from the shelve → loading screen should be **visible** (not black) with progress bar animating
4. After game loads, use menu/restart button to return to main menu → fade + loading screen should work
5. Select another game → verify loading screen visible again
6. Confirm no black-flash artifacts during transition
