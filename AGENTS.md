# Project

Asymmetric VR local party game that contains various mini games using Godot 4

## Project Structure

- `docs/` - contains all the documentation about this game
- `docs/tasks/` - contains all the open and finished tasks for this game
- `docs/adr/` - Architecture Decision Records
- `main/` - Core VR game
- `game-client/` - SvelteKit smartphone controller app (see game-client/AGENTS.md)
- `mods-unpacked/KumaGee-VRCore/` - Mini-games
- `addons/` - Godot plugins
- `assets/` - Raw art assets (characters, textures, sounds, particles)
- `build/` - Export output (`build/web/` served by HttpServer on port 8484)
- `shader/` - Custom GLSL shaders
- `theme/` - Godot theme resources
