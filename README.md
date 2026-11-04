## Important Notes

- Do not add any blend files! It causes the import to not include any of the uids

## Phone Controller

Phones connect through the game-client SPA served by Godot's built-in HTTP server.

- Controller URL: `http://<host>:8484/` (`http://localhost:8484/` on the same machine)
- WebSocket signaling: `ws://<host>:14412`

Port config: `main/utils/http_server.gd` (`@export var port: int = 8484`).

## Debug Keys

All chords use `Ctrl+Alt` with `Shift` **not** held.

### Menu / game shelve (`main/game_shelve.gd`)

- `1..9` / `KP_1..9` — start the visible game at that index (1 = Castle Defense, 2 = Ghost Hunter, 3 = Vortex Volley)
- `Ctrl+Alt+1..9` — toggle-select game by index (press again to deselect)
- `Ctrl+Alt+Enter` / `Ctrl+Alt+KP_Enter` — start the selected game

### In-game phase advance (`main/base_game.gd`)

- `Ctrl+Alt+Enter` — force `prepare -> game`; games may override `_debug_advance()` to also end the game early

### AI players (`main/utils/game_settings.gd`)

- `Ctrl+Alt+Up` — increase AI count
- `Ctrl+Alt+Down` — decrease AI count
- Range 0..8, default 0; emits `ai_count_changed`

### Mini-game specific

- Castle Defense `ui/element_select.gd` — `Ctrl+Alt+Enter` advances
- Castle Defense `arrows/arrow_spawner.gd` — `Ctrl+Alt+Shift+1..6` spawn arrow types

## Credits

<!-- - [Pirate Kit](https://kenney.nl/assets/pirate-kit) -->
<!-- - [Blunderbass](https://sketchfab.com/3d-models/stylized-blunderbuss-hand-painted-f3ef63310a7047a39de58cff734f56c8) -->
<!-- - [Halloween](https://kaylousberg.itch.io/halloween-bits) -->
<!-- - [Tavern](https://goryana.itch.io/medieval-slavic-tavern-game-assets) -->
<!-- - [Characters](https://kenney.nl/assets/animated-characters-protagonists) -->

### Models

- [Cube Pets](https://kenney.nl/assets/cube-pets)
- [Skeletons](https://kaylousberg.itch.io/kaykit-skeletons)
- [Living Room](https://goryana.itch.io/2d-and-3d-living-room-game-assets)
- [Halloween Room](https://goryana.itch.io/2d-and-3d-halloween-game-assets)
- [Character Animations](https://kaylousberg.itch.io/kaykit-character-animations)

### UI

- [Font](https://fonts.google.com/specimen/Luckiest+Guy?categoryFilters=Feeling:%2FExpressive%2FPlayful&preview.script=Latn&preview.lang=ace_Latn)
- [Emoji Font](https://fonts.google.com/noto/specimen/Noto+Color+Emoji?query=emoji)
- [Those Awesome Guys](https://thoseawesomeguys.com/prompts/)

### BGM

- [Home World](https://dova-s.jp/bgm/detail/4041)
- [Castle Defense](https://dova-s.jp/bgm/detail/22829)
- [Drawing](https://dova-s.jp/bgm/detail/23412)

### SFX

- [Poof of smoke](https://pixabay.com/sound-effects/film-special-effects-poof-of-smoke-87381/)
- [Blackhole](https://pixabay.com/sound-effects/film-special-effects-black-hole-55468/)
- [Soul Steal](https://pixabay.com/sound-effects/film-special-effects-soul-steal-02-43483/)
- [Button Press](https://pixabay.com/sound-effects/film-special-effects-button-press-382713/)
