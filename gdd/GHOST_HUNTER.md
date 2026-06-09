# Ghost Hunter

There is no hard cap in the player count, it's playable with at least 2 players. The game scales based on the player count

## Design Pillars
1. **Cat-and-mouse tension** — Both sides are blind to each other by default. Every reveal is earned, every escape is clever.
2. **Asymmetric rescue economy** — Capturing a ghost isn't the end; teammates can intervene. The round stays alive until the last ghost is secured.
3. **Party-friendly elimination** — No one sits out. Captured ghosts can be rescued, and eliminated ghosts stay engaged through the rescue dynamic.

## Core Features

### For the VR Player (Ghost Hunter)
- First-person view inside a handcrafted haunted house (2–3 layout variants, selected randomly each round).
- **Flash Device** – Emits a bright pulse that briefly reveals nearby ghosts (recharge time of 4s). Also purges haunted objects, forcing possessing ghosts out.
- **Ecto-Vacuum** – Capture tool. Sucks in a fully visible ghost over ~3 seconds. While actively sucking, the Hunter moves slowly. After successful capture the vacuum has a small cooldown of 3s
- **Wrist Tablet** – Shows house map with last known ghost interaction pings, task locations (ghost objectives are visible to Hunter as map markers — the Hunter knows what they're trying to do), and charge count for Flash Device.
- **Proximity Audio** – Hears ghost whispers and footstep-like sounds when a ghost is near. Pitch and volume indicate distance and activity.

**Visibility Rule:** Hunter cannot see ghosts unless revealed by the Flash Device. Ghosts that are phasing, haunting objects, or moving normally are completely invisible to the naked eye. The Flash reveal lasts ~4 seconds.

### For the Ghost Players (Shared Screen)
- **Single top-down view** of the haunted house in 3D on a shared TV/monitor.
  - Each player appears as a colored ghosts. The Hunter appears on the shared-screen map only when within ~10 meters of any ghost. The Hunter disappears when he moves out of range. This gives ghosts directional warning that the Hunter is near, without perfect omniscience.
  - Ghosts can see each other's positions on the shared screen at all times.
- **Abilities** (no cooldowns — usage is limited by context and opportunity):
  - **Phase Walk** – Move through walls. Ghost is slowed while inside walls and leaves a faint shimmer trail the Hunter can spot if looking closely. Passing through a wall creates a brief visual ripple on the shared screen visible to other ghosts.
     - After using, there is a small cooldown of 3s before using again
  - **Haunt** – Flicker lights, creak doors, or possess an object (doll, mannequin, furniture). While haunting, the ghost is hidden inside the object. The object may twitch or emit subtle audio.
     - **Initiation:** Walk close to an object and press **A** to enter it.
     - **Trigger effect:** Press **A** again to trigger the object's effect (flicker, creak, etc.).
     - **Exit:** Press **B** to leave the object voluntarily.
     - **Rescue:** Haunting the Ecto-Vacuum and press A to releasae the captured ghost one by one.
- **Mischief Tasks** – Each round, ghosts must complete hidden objectives. Tasks scale with ghost count: 2 tasks for 1 ghost, 3 for 2 ghosts, 4 for 3 ghosts, 5 for 4 ghosts. Tasks appear as highlighted markers on the shared-screen map. A task is completed by a ghost standing near its marker for ~3 uninterrupted seconds.
- **Control Scheme** – Phone touch controls (joystick + action buttons). The phone screen shows no game data — it acts only as a controller. All info (map, task markers, ghost positions) is displayed on the shared desktop screen.
  - **Left joystick** – Movement.
  - **A button** – Haunt (enter object), trigger object effect, or interact.
  - **B button** – Leave haunted object / cancel.

## Game Loop (Per Round)

### 1. Setup Phase (20 seconds)
- Ghosts receive their mischief tasks (markers appear on the shared-screen map).
- VR player sees the house layout on their Wrist Tablet with task markers (so they know what ghosts are trying to do).

### 2. Hunt Phase (5 minutes)
- **Ghosts** move around the house, complete Mischief Tasks, and avoid the Hunter.
- **VR player** navigates rooms, listens for audio cues, uses Flash to reveal ghosts, and captures them with the Ecto-Vacuum.
- **Capture sequence:**
  1. Hunter uses Flash → ghost becomes visible for ~4 seconds (if in range and line-of-sight).
  2. Hunter aims Ecto-Vacuum at the revealed ghost and holds the trigger. After ~3 seconds of continuous suction, the ghost is captured.
  3. While the Hunter is sucking, they move at reduced speed. If they break line-of-sight or the ghost moves behind cover, capture progress resets.
  4. Any other ghost can **Haunt the vacuum** (must be near it) → trigger effect to release captured ghost.
   5. The Hunter can **Flash a haunted vacuum** to purge the haunting ghost, forcing them out and resetting the rescue attempt.

### 3. Haunt Surge (triggers at 4:30 if any ghost remains uncaptured)
- All remaining ghosts become fully visible (no Flash needed) and slowed by 30%.
- Hunter must survive 30 seconds without being touched by a ghost.
- If a ghost touches the Hunter → Ghosts win instantly. If the Hunter survives → draw (no one scores).
- During Surge, the Hunter recovers 1 Flash charge (if any were used).

### 4. Win Conditions
- **Ghosts win** – Complete all Mischief Tasks (scaled to ghost count) before all ghosts are captured.
- **Hunter wins** – Capture all ghosts before tasks are completed, or survive Haunt Surge without being touched.

### 5. Scoring
- Hunter win → VR player gets full points.
- Ghosts win → Points shared among surviving ghosts based on tasks completed.
- Bonuses:
  - **"Bamboozle"** – Ghost tricks Hunter into wasting a Flash charge on nothing (no ghost in range).
  - **"Rescue"** – A ghost successfully rescues a captured teammate.
  - **"Clutch Capture"** – Final ghost caught in the last 10 seconds.
