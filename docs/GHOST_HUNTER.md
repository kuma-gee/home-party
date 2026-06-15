# Ghost Hunter — REPLACED

> **This game has been replaced by [Hide & Seek](./HIDE_AND_SEEK.md).**
>
> Ghost Hunter was planned but never implemented beyond early prototyping.
> It occupied the same "VR seeks, mobiles hide" design space as Hide & Seek,
> which was chosen for its lower complexity, faster rounds, and stronger
> VR physics interaction. This document is kept for reference only.

# Ghost Hunter

There is no hard cap in the player count, it's playable with at least 2 players. The game scales based on the player count.
Everyone is playing together in the same room.

- **Minimum Players:** 2
- **Recommended Players:** 3–6

## Design Pillars
1. **Cat-and-mouse tension** — Both sides are blind to each other by default. Every reveal is earned, every escape is clever.
2. **Asymmetric rescue economy** — Capturing a ghost isn't the end; teammates can intervene. The round stays alive until the last ghost is secured.
3. **Party-friendly elimination** — No one sits out. Captured ghosts can be rescued, and eliminated ghosts stay engaged through the rescue dynamic.

## Core Features

### For the VR Player (Ghost Hunter)
- First-person view inside a handcrafted haunted house (2–3 layout variants, selected randomly each round).
- **Movement: Smooth locomotion** (thumbstick). No teleport. Ghosts see the Hunter on their shared screen when within 10m — teleport would let the Hunter bypass this warning range instantly, breaking the cat-and-mouse tension.
- **Flash Device** – Emits a bright pulse that briefly reveals ghosts (recharge time of 3s). Targets the area in front in a 45° cone, range of 2m, and reveals the player's location to ghosts. Also purges haunted objects within range, forcing possessing ghosts out.
  - Shows visuals when ghosts are nearby
- **Ecto-Vacuum** – Capture tool. Sucks in a fully visible ghost over ~3 seconds (range 3m, requires line-of-sight). While actively sucking, the Hunter moves at 50% speed (cannot sprint or cancel into sprint).
- **Wrist Tablet** – Shows house map with last known ghost interaction pings, task locations (ghost objectives are visible to Hunter as map markers — the Hunter knows what they're trying to do), and charge count for Flash Device.

**Visibility Rule:** Hunter cannot see ghosts unless revealed by the Flash Device. Ghosts that are phasing, haunting objects, or moving normally are completely invisible to the naked eye. The Flash reveal lasts ~4 seconds.

**VR Control Scheme:**
- **Left thumbstick** – Smooth locomotion (move).
- **Right thumbstick** – Snap-turn (rotate view).
- **Right trigger** – Flash Device (pulse).
- **Left grip + trigger** – Activate/deactivate Ecto-Vacuum (hold to aim and suck).
- **Wrist Tablet** – Toggle map on non-dominant wrist (glance down or press button).

**VR Comfort Settings (player-configurable in menu):**
- **Vignette intensity** — Off / Low / Default / High. Higher values darken peripheral vision more during movement.
- **Movement direction** — Head-relative (default) or Controller-relative.
- **Snap-turn angle** — 15° / 30° / 45° (default 45°).

### For the Ghost Players (Shared Screen)
- **Single top-down view** of the haunted house in 3D on a shared TV/monitor.
  - Each player appears as a colored ghosts. The Hunter appears on the shared-screen map only when within ~10 meters of any ghost. The Hunter disappears when he moves out of range. This gives ghosts directional warning that the Hunter is near, without perfect omniscience.
  - Ghosts can see each other's positions on the shared screen at all times.
- **Abilities** (no cooldowns — usage is limited by context and opportunity):
  - **Phase Walk** – Move through walls. Ghost is slowed to 50% speed while inside walls and leaves a faint shimmer trail the Hunter can spot if looking closely. Passing through a wall creates a brief visual ripple on the shared screen visible to other ghosts.
  - **Haunt** – Flicker lights, creak doors, or possess an object (doll, mannequin, furniture). While haunting, the ghost is hidden inside the object. The object may twitch or emit subtle audio.
     - **Initiation:** Walk close to an object and press **A** to enter it.
     - **Trigger effect:** Press **A** again to trigger the object's effect (flicker, creak, etc.).
     - **Exit:** Press **B** to leave the object voluntarily.
      - **Rescue:** Haunting the Ecto-Vacuum (same proximity as object haunt) and press **A** to release the captured ghost one by one.
- **Mischief Tasks** – Each round, ghosts must complete hidden objectives. Tasks scale with ghost count: 2 tasks for 1 ghost, 3 for 2 ghosts, 4 for 3 ghosts, 5 for 4 ghosts. Tasks appear as highlighted markers on the shared-screen map. A task is completed by a ghost standing near its marker for ~3 uninterrupted seconds.
- **Control Scheme** – Phone touch controls (joystick + action buttons). The phone screen shows no game data — it acts only as a controller. All info (map, task markers, ghost positions) is displayed on the shared desktop screen.
  - **Left joystick** – Movement.
  - **A button** – Haunt (enter object), trigger object effect, or interact.
  - **B button** – Leave haunted object / cancel.

## Game Loop for one game

### 1. Setup Phase (20 seconds)
- Ghosts receive their mischief tasks (markers appear on the shared-screen map).
- VR player sees the house layout on their Wrist Tablet with task markers (so they know what ghosts are trying to do).

### 2. Hunt Phase (5 minutes)
- **Ghosts** move around the house, complete Mischief Tasks, and avoid the Hunter.
- **VR player** navigates rooms, uses Flash to reveal ghosts, and captures them with the Ecto-Vacuum.
- **Capture sequence:**
  1. Hunter uses Flash → ghost becomes visible for ~4 seconds (if in range and line-of-sight).
  2. Hunter aims Ecto-Vacuum at the revealed ghost and holds the trigger. After ~3 seconds of continuous suction, the ghost is captured.
  3. While the Hunter is sucking, they move at reduced speed.
  4. Any other ghost can **Haunt the vacuum** (must be near it) → trigger effect to release captured ghost.
  5. The Hunter can **Flash a haunted vacuum** to purge the haunting ghost, forcing them out and resetting the rescue attempt.

### 3. Haunt Surge (triggers when all tasks have been completed)
- All remaining ghosts become fully visible and slowed by 30%.
- Flashes now only stun the ghost (brief immobilize) — capturing is not possible anymore.
- In this phase ghosts cannot possess anything → ghosts cannot be rescued anymore.
- Hunter must reach the exit within 30 seconds without being touched by a ghost.
- **Touching** = any collision between a ghost's body and the Hunter (proximity is not enough — actual contact required).
- If a ghost touches the Hunter or 30s passes → Ghosts win instantly.
- If the Hunter gets to the exit → draw (no one scores).

### 4. Win Conditions
- **Ghosts win** – Complete all Mischief Tasks (scaled to ghost count) before all ghosts are captured.
- **Hunter wins** – Capture all ghosts before tasks are completed, or survive Haunt Surge without being touched.

### 5. Scoring
- **Hunter win** → VR player gets **10 points**.
- **Ghosts win** → Each surviving ghost gets **5 points**. Additionally, **2 points per completed mischief task** are added to the team pool and split equally among surviving ghosts.
- **Bonuses:**
  - **"Rescue"** (+3 points) – A ghost successfully rescues a captured teammate.
  - **"Clutch Capture"** (+3 points) – Final ghost caught in the last 10 seconds of the Hunt Phase.
