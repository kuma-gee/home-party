# 006 — Haunt Mechanic & Interactive Objects

- [ ] Approved by user

## What to build

Ghosts can haunt objects in the house. Hauntable objects are placed throughout the house — dolls, mannequins, furniture, mirrors. A ghost approaches an object and presses A to enter it, becoming hidden inside. The possessed object shows subtle signs: twitching animation, faint audio cues.

Once inside, pressing A triggers the object's effect (lights flicker, door creaks, doll laughs). Pressing B exits the object voluntarily. A ghost hiding inside an object is not visible to the Hunter — but the Flash Device purges haunted objects, forcing the ghost out (this interaction is handled fully in task 008).

Objects also serve as the rescue tool later: a ghost haunts the Ecto-Vacuum to release captured teammates (task 008).

## Acceptance criteria

- [ ] At least 6 hauntable objects placed across the house (3+ distinct types)
- [ ] Object types have distinct identities: e.g., doll (creepy), lamp (flickers), door (creaks), mannequin (rotates), radio (static burst), mirror (distortion)
- [ ] Ghost near an object + press A → ghost disappears and the object becomes haunted
- [ ] Haunted object plays a subtle idle animation (twitch, sway, rattle)
- [ ] Haunted object emits subtle audio (creak, whisper, hum) audible to Hunter when nearby
- [ ] Press A while haunting → triggers the object's effect (visual + audio)
- [ ] Triggered effect is noticeable to the VR Hunter (heard, seen) — draws attention
- [ ] Press B while haunting → ghost exits the object and reappears next to it
- [ ] Ghost is hidden from Hunter's view while inside an object (same visibility rules — invisible unless revealed by Flash)
- [ ] Multiple ghosts can haunt different objects simultaneously
- [ ] Two ghosts cannot haunt the same object at the same time

## Blocked by

- [002-house-environment](./002-house-environment.md) — needs the house and hauntable object placement spots
- [003-ghost-player-movement](./003-ghost-player-movement.md) — needs ghost movement and A/B input

## Design notes

- Objects should use Area3D for ghost proximity detection (haunt interaction zone)
- The haunted state can be managed by a `haunted_by` property on the object referencing the ghost
- Object effects should be cooldown-limited per haunt session (e.g., can only trigger effect every 5s) to prevent spam
- Interaction with Flash (task 004/008): when Flash hits a haunted object, the ghost is ejected. Wire this as an integration point.
- The Ecto-Vacuum rescue haunting (task 008) reuses the same Haunt mechanic but with a special interaction target.
