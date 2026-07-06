---
name: start-minigame
description: Start a specific mini-game in the running Godot game during tester-agent verification.
---

# Start Specific Mini-game

Use this when tester must verify one mini-game, not hub/menu behavior.

## Required inputs

- Mini-game name or folder, e.g. `draw-and-guess`, `castle-defense`, `vortex-volley`, `hide-and-seek`.
- Prefer exact `GameResource` `.tres` path when prompt provides it.

Known core mini-game resources:

| Mini-game | GameResource path |
|---|---|
| Castle Defense | `res://mods-unpacked/KumaGee-VRCore/castle-defense/castle_defense.tres` |
| Draw & Guess | `res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tres` |
| Vortex Volley | `res://mods-unpacked/KumaGee-VRCore/vortex-volley/vortex_volley.tres` |
| Hide and Seek | `res://mods-unpacked/KumaGee-VRCore/hide-and-seek/hide_and_seek.tres` |

## Start from hub via MCP

1. Start Godot:

   ```text
   godot.launch_game(headless=false)
   godot.wait_for_godot(timeout=15)
   ```

2. Find `GameShelve` if path uncertain:

   ```text
   godot.find_node(name="GameShelve")
   ```

   Usual path after hub loads:

   ```text
   /root/Staging/Scene/MenuWorld/GameShelve
   ```

3. Select game by resource path:

   ```text
   godot.call_method(
     path="/root/Staging/Scene/MenuWorld/GameShelve",
     method="select_game_with_path",
     args=["res://mods-unpacked/KumaGee-VRCore/draw-and-guess/draw_and_guess.tres"]
   )
   ```

4. Start selected game:

   ```text
   godot.call_method(
     path="/root/Staging/Scene/MenuWorld/GameShelve",
     method="start_selected_game",
     args=[]
   )
   ```

5. Wait briefly, then confirm loaded game:

   ```text
   godot.get_scene_tree()
   godot.find_node(name="DrawAndGuess", contains=true)
   ```

   If exact root name unknown, use `get_scene_tree()` and look under:

   ```text
   /root/Staging/Scene/
   ```

## Alternative: debug hotkeys

Hub supports keyboard debug shortcuts in `main/game_shelve.gd`:

- `Shift+1`..`Shift+9`: select/deselect indexed game from loaded game list.
- `Shift+F1`: start selected game.

Prefer MCP `select_game_with_path()` because game order can change.

## Starting gameplay phase inside mini-game

Loading mini-game scene may leave it in prepare/lobby phase. To enter game phase for logic tests:

1. Locate loaded mini-game root with `godot.get_scene_tree()` or `godot.find_node(...)`.
2. If game script has `_debug_start_game`, call it:

   ```text
   godot.call_method(path="<game_root_path>", method="_debug_start_game", args=[])
   ```

3. If no `_debug_start_game` exists and root inherits `BaseGame`, direct call may work for tests:

   ```text
   godot.call_method(path="<game_root_path>", method="_start_game", args=[])
   ```

4. Verify `is_game_phase == true` via `godot.get_properties(path="<game_root_path>")`.

If neither path works, report testing blocker and suggest adding `_debug_start_game` to mini-game script. Do not add code from tester.

## Mobile players

If mini-game needs phone players, use `connect-mobile-player` after mini-game loads. Then test controls through `http://localhost:8484/`.

## Cleanup

Always stop Godot after verification:

```text
godot.stop_game()
```
