# 007 — Full Settings Panel

Reference: `docs/GDD.md` — Quick Settings Menu, Full Settings Panel

## Summary

The Full Settings Panel described in the GDD is currently a stub (`vr_space.gd:72` is `pass`). This task implements the panel as a floating VR overlay that replaces the Quick Settings menu when the user clicks "Settings." It provides audio volume controls (Master, SFX, Music) and basic graphics options (render scale, anti-aliasing toggle). Settings persist to a `user://` ConfigFile with auto-save on change.

The scope is intentionally reduced from the original GDD table: Voice volume, Quality preset slider, Foveated rendering toggle, Controller diagram, and Language dropdown are deferred.

## What to build

### 1. Audio Bus Layout

Create `default_bus_layout.tres` with three audio buses:

```
Master (0 dB)
├── SFX (0 dB)
└── Music (0 dB)
```

Update existing audio systems to use the correct bus:
- **`BGMManager`** → route its `AudioStreamPlayer` to the `"Music"` bus. Remove its internal `volume_db` management — volume is now controlled by the bus level.
- **`AudioManager`** → route its pool of `AudioStreamPlayer` nodes to the `"SFX"` bus.
- Master bus: default Godot `"Master"` bus remains as-is.

### 2. User Settings Autoload

Create `main/utils/user_settings.gd` as a new autoload (register in `project.godot`).

- Stores settings in `user://settings.cfg` (Godot `ConfigFile` format)
- Auto-saves on every change (no Apply button)
- Loads on `_ready()`
- Default values:

```gdscript
# audio
master_volume: float      # 0.0–1.0, mapped linearly to dB range -60..0
sfx_volume: float         # 0.0–1.0, mapped linearly to dB range -60..0
music_volume: float       # 0.0–1.0, mapped linearly to dB range -60..0

# graphics
render_scale: float       # 0.5–2.0, step 0.25
antialiasing: bool        # true = FXAA on
```

Public API:

```gdscript
signal setting_changed(section: String, key: String)

func get_master_volume() -> float
func set_master_volume(value: float)
func get_sfx_volume() -> float
func set_sfx_volume(value: float)
func get_music_volume() -> float
func set_music_volume(value: float)
func get_render_scale() -> float
func set_render_scale(value: float)
func get_antialiasing() -> bool
func set_antialiasing(value: bool)

func save() -> void        # called on every setter
func load() -> void        # called in _ready()
```

Each setter updates the in-memory value, calls `save()`, emits `setting_changed`, and applies the change immediately to the live system (e.g., calling `AudioServer.set_bus_volume_db()` or setting viewport properties).

### 3. Settings Panel 3D Scene

Create `main/vr/settings_panel.tscn` — a floating 3D panel.

Structure (mirrors `vr_menu_panel.tscn`):

```
SettingsPanel (Node3D, script = settings_panel.gd)
└── Viewport2Din3D
    ├── Screen (MeshInstance3D)
    └── Viewport
        └── SettingsPanelUI (Control, packed from settings_panel_ui.tscn)
```

**Script `main/vr/settings_panel.gd`** — class_name `SettingsPanel`, extends `Node3D`.

```gdscript
signal back_pressed

func _ready() -> void
  # Find the UI Control inside the viewport
  # Connect UI button signals -> back_pressed
```

### 4. Settings Panel 2D UI

Create `main/vr/settings_panel_ui.tscn` — a `PanelContainer` Control node.

Layout (vertical):

```
Settings (title label)
─ Separator ─
── Audio Section ──
  Master Volume [=========o===]  (HSlider + value label)
  SFX Volume    [=========o===]
  Music Volume  [=========o===]
── Graphics Section ──
  Render Scale  [===o=========]  (HSlider, 0.5–2.0, step 0.25, show ×1.0)
  Anti-Aliasing [Toggle button]  (CheckBox / Button)
─ Separator ─
[Back Button]
```

All UI elements bind to `UserSettings` properties via signals. Moving a slider calls the corresponding `set_*` method on `UserSettings`. The slider value is initialised from the current setting on `_ready()`.

### 5. Integration in VRSpace

Modify `main/vr/vr_space.gd`:

- `_on_settings_pressed()`:
  1. Close the current Quick Settings menu (`menu_function.close_menu()`)
  2. Instantiate `settings_panel.tscn` as a child of the same anchor used by the menu
  3. Connect `back_pressed` on the panel → close the panel and unpause (same logic as `_on_menu_closed`)

- The overlay mesh and pause state are already active from the Quick Settings menu, so they remain active.

- Consider making the Settings Panel follow the same attach point / transform as the menu. Since `XRToolsFunctionMenu` owns the anchor, the settings panel can be parented to the same `MenuAnchor` or to a sibling under the left controller.

### 6. Apply Settings at Runtime

When `UserSettings` values change, immediately apply:

- **Master volume**: `AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))`
- **SFX volume**: `AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(volume))`
- **Music volume**: `AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(volume))`
- **Render scale**: `get_viewport().scaling_3d_scale = value` (on the main `SubViewport`)
- **Anti-aliasing**: `get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if enabled else Viewport.SCREEN_SPACE_AA_DISABLED`

## Files touched

| File | Change |
|------|--------|
| `main/utils/user_settings.gd` | **New** — UserSettings autoload, ConfigFile persistence, signals |
| `main/vr/settings_panel.tscn` | **New** — 3D floating panel scene |
| `main/vr/settings_panel.gd` | **New** — Script for the panel node |
| `main/vr/settings_panel_ui.tscn` | **New** — 2D Control UI for the panel |
| `main/vr/vr_space.gd` | **Modified** — `_on_settings_pressed()` opens settings panel, handles back |
| `main/utils/bgm_manager.gd` | **Modified** — Route to `"Music"` bus, remove internal volume management |
| `main/utils/audio_manager.gd` | **Modified** — Route SFX pool to `"SFX"` bus |
| `default_bus_layout.tres` | **New** — 3-bus audio layout (Master, SFX, Music) |
| `project.godot` | **Modified** — Add `UserSettings` autoload, set audio bus layout |

## Data flow

```
UserSettings (autoload)
  ↓ setting_changed signal
  ↓
  AudioServer.set_bus_volume_db()  ← immediate dB update
  get_viewport().scaling_3d_scale  ← immediate scale update
  get_viewport().screen_space_aa   ← immediate AA toggle

UserSettings.save()
  ↓
  ConfigFile → user://settings.cfg  ← persists on every change

SettingsPanelUI (slider moved)
  ↓ signal
SettingsPanel.gd
  ↓ call
UserSettings.set_*()
```

## New signals / functions / classes

### `UserSettings` (autoload, `Node`)

```gdscript
signal setting_changed(section: String, key: String)

func _ready() -> void          # loads config, applies defaults
func save() -> void            # writes ConfigFile
func load_settings() -> void   # reads ConfigFile

# Audio
func get/set_master_volume() -> float
func get/set_sfx_volume() -> float
func get/set_music_volume() -> float

# Graphics
func get/set_render_scale() -> float
func get/set_antialiasing() -> bool
```

### `SettingsPanel` (extends `Node3D`)

```gdscript
signal back_pressed

func _ready() -> void     # find UI root, connect signals
```

## Migration / compatibility

None — no breaking changes. Existing `AudioManager` SFX calls continue to work (now routed through the SFX bus). `BGMManager.set_volume_db()` is removed; volume is controlled via the Music bus instead. The `UserSettings` ConfigFile is created on first launch with defaults.

## Acceptance criteria

- [ ] Audio buses (Master, SFX, Music) exist in `default_bus_layout.tres` and are loaded by the project
- [ ] `BGMManager` plays through the Music bus
- [ ] `AudioManager` plays through the SFX bus
- [ ] `UserSettings` autoload is registered and loads `user://settings.cfg` on startup
- [ ] Master/SFX/Music sliders in the settings panel change the corresponding bus volume in real-time
- [ ] Render scale slider changes the viewport's `scaling_3d_scale` immediately
- [ ] Anti-aliasing toggle enables/disables FXAA immediately
- [ ] Settings persist across game restarts (ConfigFile is written and read)
- [ ] Clicking "Settings" in Quick Settings menu closes the menu and opens the settings panel
- [ ] Clicking "Back" in the settings panel closes it and unpauses the game
- [ ] Game remains paused while the settings panel is open
- [ ] No crashes when rapidly adjusting sliders or toggling back/forth between menu and settings

## Blocked by

None — can start immediately.
