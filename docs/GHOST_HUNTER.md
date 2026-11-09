# Ghost Hunter

There is no hard cap in the player count, it's playable with at least 2 players. The game scales based on the player count.
Everyone is playing together in the same room.

- **Minimum Players:** 2
- **Recommended Players:** 3–6

## Design Pillars
1. **Cat-and-mouse tension** — Both sides are blind to each other by default. Every reveal is earned, every escape is clever.
2. **Asymmetric rescue economy** — Capturing a ghost isn't the end; teammates can intervene. The round stays alive until the last ghost is secured.
3. **Party-friendly elimination** — No one sits out. Captured ghosts can be rescued, and eliminated ghosts stay engaged through the rescue dynamic.
4. **Escalating sabotage** — Ghosts fight back by glitching the Hunter's devices as they complete tasks. The round itself never changes shape: same roles, same win conditions, all the way to the clock.

## Core Features

### For the VR Player (Ghost Hunter)
- First-person view inside a handcrafted haunted house (2–3 layout variants, selected randomly each round).
- **Movement: Smooth locomotion** (thumbstick). No teleport. Ghosts see the Hunter on their shared screen when within 10m — teleport would let the Hunter bypass this warning range instantly, breaking the cat-and-mouse tension.
- **Flash Device** – Emits a bright pulse that briefly reveals ghosts (recharge time of 3s). Targets the area in front in a 45° cone, range of 2m, and reveals the player's location to ghosts. Also purges haunted objects within range, forcing possessing ghosts out. A ghost hit by the flash is shown with a visible highlight for the reveal duration.
- **Ecto-Vacuum** – Capture tool. Sucks in a fully visible ghost over ~3 seconds (range 3m, requires line-of-sight). While actively sucking, the Hunter moves at 50% speed.
- **Flash Device Display** – The screen on the back of the Flash Device (read it while holding the device) shows the house map with last known ghost interaction pings and the flash charge.

**Visibility Rule:** Hunter cannot see ghosts unless revealed by the Flash Device. Ghosts that are phasing, haunting objects, or moving normally are completely invisible to the naked eye. The Flash reveal lasts ~4 seconds.

**VR Control Scheme:**
- **Left thumbstick** – Smooth locomotion (move).
- **Right thumbstick** – Snap-turn (rotate view).
- **Right trigger** – Flash Device (pulse).
- **Left grip + trigger (hold)** – Aim and suck with the Ecto-Vacuum.
- **Flash Device Display** – Hold the Flash Device and look at its screen to see the house map, ghost interaction pings, and flash charge.

**VR Comfort Settings (player-configurable in menu):**
- **Vignette intensity** — Off / Low / Default / High. Higher values darken peripheral vision more during movement.
- **Movement direction** — Head-relative (default) or Controller-relative.
- **Snap-turn angle** — 15° / 30° / 45° (default 45°).

### For the Ghost Players (Shared Screen)
- **Single top-down view** of the haunted house in 3D on a shared TV/monitor.
  - Each player appears as a colored ghost. The Hunter appears on the shared-screen map only when within ~10 meters of any ghost. The Hunter disappears when he moves out of range. This gives ghosts directional warning that the Hunter is near, without perfect omniscience.
  - Ghosts can see each other's positions on the shared screen at all times.
- **Abilities** (no cooldowns — usage is limited by context and opportunity):
  - **Phase Walk** – Move through walls. Activate by pressing **B** while against a wall. Ghost is slowed to 50% speed while inside walls and leaves a faint shimmer trail the Hunter can spot if looking closely. Passing through a wall creates a brief visual ripple on the shared screen visible to other ghosts.
  - **Haunt** – Flicker lights, creak doors, or possess an object (doll, mannequin, furniture). While haunting, the ghost is hidden inside the object. The object may twitch or emit subtle audio.
     - **Initiation:** Walk close to an object and press **A** to enter it.
     - **Trigger effect:** Press **A** again to trigger the object's effect (flicker, creak, etc.).
     - **Exit:** Press **B** to leave the object voluntarily.
      - **Rescue:** Walk close to the Ecto-Vacuum, press **A** to haunt it, then **hold A for 2 seconds** to release one captured ghost.
- **Mischief Tasks** – Each round, ghosts must complete objectives. Tasks scale with ghost count: **ghost count + 1** (2 tasks for 1 ghost, 3 for 2, 4 for 3, 5 for 4, and so on for more ghosts). Only ghosts see the objectives — they appear as highlighted markers on the shared-screen map. Markers do not all appear at once: the first extra marker appears ~6 s after the round starts and then one spawns every 10–15 s, never more than **players − 1** (at least 1) active at the same time. Each new marker spawns far from the active ones — at least ~8 m away — so tasks that are close to each other are never active at the same time. A task is completed by a ghost standing near its marker for ~6 uninterrupted seconds. Each completed task triggers a **Haunt Glitch** on the Hunter's devices (see Game Loop §3) — tasks are how ghosts hinder the Hunter, not how they end the round.
- **Control Scheme** – Phone touch controls (joystick + action buttons). The phone screen shows no game data — it acts only as a controller. All info (map, task markers, ghost positions) is displayed on the shared desktop screen.
  - **Left joystick** – Movement.
  - **A button** – Haunt (enter object), trigger object effect, or interact. While haunting the Ecto-Vacuum, hold **A** for 2s to release one captured ghost.
  - **B button** – Leave haunted object / cancel; press against a wall to Phase Walk.

## Game Loop for one game

### 1. Setup Phase (20 seconds)
- Ghosts receive their mischief tasks (markers appear on the shared-screen map, visible only to ghosts).
- The VR player spawns outside the front door; ghosts spawn at random spots inside the house.
- The VR player can look at the Flash Device's screen to see the house layout.

### 2. Hunt Phase (5 minutes)
- **Ghosts** move around the house, complete Mischief Tasks (each completed task glitches the Hunter's gear — §3), and avoid the Hunter.
- **VR player** navigates rooms, uses Flash to reveal ghosts, and captures them with the Ecto-Vacuum.
- **Capture sequence:**
  1. Hunter uses Flash → ghost becomes visible for ~4 seconds (if in range and line-of-sight).
  2. Hunter aims Ecto-Vacuum at the revealed ghost and holds the trigger. After ~3 seconds of continuous suction, the ghost is captured.
  3. While the Hunter is sucking, they move at reduced speed.
  4. Any other ghost can **Haunt the vacuum** (must be near it) and hold **A** for 2s → releases one captured ghost. A captured ghost is out of the house but can still see the shared-screen map.
  5. The Hunter can **Flash a haunted vacuum** to purge the haunting ghost, forcing them out and resetting the rescue attempt.

### 3. Haunt Glitches (triggered by each completed task)
- Every completed Mischief Task glitches the Hunter's gear. The round never changes phase, roles never flip, and the 5-minute clock keeps running.
- **Glitch level = number of completed tasks.** Effects stack up to their caps:
  - **Flash Device** – recharge grows (3s + 1s per level, max 6s) and the reveal shrinks (4s − 0.5s per level, min 2s). At level 3+ the device display flickers: house map and interaction pings drop out briefly.
  - **Ecto-Vacuum** – suction takes longer (3s + 0.5s per level, max 5s) and range shrinks (3m − 0.25m per level, min 1.5m).
  - **Hunter's view** – from level 2, short static-interference pulses hit the headset; at Full Haunt the interference is persistent.
- **Full Haunt** (all tasks completed) – both devices stay at max glitch and the view interference is persistent for the rest of the round. The round still resolves only by capture or by the clock.
- The shared-screen "Hunter nearby" ping (10m rule) is never glitched — the ghosts' warning system stays reliable.

### 4. Win Conditions
- **Hunter wins** – Capture **all** ghosts before the 5-minute Hunt Phase timer ends.
- **Ghosts win** – At least one ghost is still free (not captured) when the timer ends.
- No draw, no early end — the round always resolves by capture-all or by the clock.

### 5. Scoring
- **Hunter win** → VR player gets **10 points**.
- **Ghosts win** → Each surviving ghost gets **5 points**. Additionally, **2 points per completed mischief task** are added to the team pool and split equally among surviving ghosts.
- **Bonuses:**
  - **"Rescue"** (+3 points) – A ghost successfully rescues a captured teammate.
  - **"Clutch Capture"** (+3 points) – Final ghost caught in the last 10 seconds of the Hunt Phase.
