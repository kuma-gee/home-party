# 002 — House Environment

- [ ] Approved by user

## What to build

Build one complete haunted house layout — a 3D interior environment with multiple rooms, connecting corridors, doors, and walls. This is the shared physical space where both the VR Hunter and the ghosts operate. The house needs a desktop-facing top-down camera so the shared screen shows the full map.

The layout should support the core gameplay: rooms give ghosts places to hide and haunt objects, corridors create chase routes, and walls enable Phase Walk traversal. Lighting should be dim/spooky to reinforce the hunter theme.

Placement spots for hauntable objects (dolls, mannequins, furniture) should be marked or reserved even if the objects themselves come in a later task.

## Acceptance criteria

- [ ] House 3D environment with at least 4 distinct rooms connected by doors and corridors
- [ ] Walls block both VR player movement and ghost movement (except via Phase Walk)
- [ ] VR player can physically navigate all accessible areas (no collision gaps)
- [ ] Desktop camera renders a top-down orthographic view of the entire house
- [ ] Top-down view is the default shared-screen display during gameplay
- [ ] House has spooky lighting (dim ambient, point lights in key rooms)
- [ ] At least 6 locations reserved for hauntable objects (visible markers or empty nodes)
- [ ] House boundaries prevent players from escaping the play area

## Blocked by

- [001-game-scaffold](./001-game-scaffold.md) — needs the main scene to add the house into

## Design notes

- The house does not need to be a full building exterior — a self-contained interior-only layout is fine as long as walls/rooms feel like a house
- Consider a single-floor layout with 5–7 rooms for the first variant; additional layout variants can be added later
- Hauntable object spots: living room (TV, couch), bedroom (doll, wardrobe), hallway (painting, mirror), kitchen (cabinet, chair)
