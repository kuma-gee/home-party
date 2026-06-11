# 015 — Plushie Animal Variety & Visual Polish

- [ ] Approved by user

## What to build

Replace the placeholder mesh on plushies with a set of distinct animal models. Each time a plushie spawns (player connects), a random animal is chosen from a predefined pool. Players connecting later get different animals, creating a colorful menagerie on the couch.

**Animals (initial set):**
- Cat (round body, pointy ears)
- Bear (stout, rounded)
- Bunny (long ears, round body)
- Dog (floppy ears, longer snout)
- Fox (pointy ears, bushy tail)

Each animal is a low-poly stylized mesh that reads clearly in VR at couch distance. The models use a shared material palette — each plushie gets a tint/shade variation tied to the player's color from `PlayerList`. The color goes on the body, and the animal features (ears, tail, face) are colored to match a cohesive toy aesthetic.

The player number tag wraps around the animal's neck area as a collared tag (described in GDD: "a tag around the animals neck"), using a `Label3D` parented to a neck bone or attachment point.

**Key design decisions:**
- Animal models are created as separate `.tscn` files or as `MeshLibrary` entries, pickable from a resource array in the plushie spawner
- Each animal scene has an identified "tag attach point" (a `Marker3D` child) for the player number tag
- The tag is a small card/tag mesh with `Label3D` for the number — positioned around the neck, not floating above
- Player's color tints the animal body via material override on spawn, keeping features (ears, face) visible
- Physics collision shape matches each animal's approximate bounding shape (not per-poly)
- Models are low-poly with flat shading for a toy-like look

## Acceptance criteria

- [ ] 5 distinct animal models exist (cat, bear, bunny, dog, fox) as plushie variants
- [ ] Each new plushie gets a random animal type on spawn
- [ ] The player number tag appears around the animal's neck (not floating above)
- [ ] The animal body is tinted with the player's assigned color from `PlayerList`
- [ ] Animal features (ears, face, tail) remain readable despite the body tint
- [ ] Animals are clearly distinguishable from each other at VR scale and distance
- [ ] Plushies spawned later get different random animals (no forced dedup unless pool exhausted)
- [ ] Each animal variant has appropriate collision (not all using the same sphere)
- [ ] The tag around the neck is a small card/tag mesh with visible player number text

## Blocked by

- [011-plushie-spawn-physics](./011-plushie-spawn-physics.md) — needs the plushie system to attach new meshes to

## Design notes

- Create animals as separate `.tscn` files under `assets/plushie/` (e.g., `plushie_cat.tscn`, `plushie_bear.tscn`)
- Each scene is a `RigidBody3D` (or `XRToolsPickable`) with the animal mesh as a child
- Use a `@export var animal_name: String` and `@export var tag_attachment: NodePath` for generic handling
- The plushie spawner picks from an `@export var animal_scenes: Array[PackedScene]` resource
- Collision shapes should be approximate — capsule for bunny, box for bear, etc.
- Tag mesh: a small quad/card with a `Label3D` child, positioned at the neck attachment point
- Consider adding a subtle physics-based wobble to ears/tail for extra toy-like feel (stretch goal)
