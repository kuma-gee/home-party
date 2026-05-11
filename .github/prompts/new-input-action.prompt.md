---
description: "Add a new named input action across both the Godot server (GameClient signal handling) and the Svelte web client (connectionStore emit call)."
argument-hint: "Input name and type, e.g. 'attack (button)' or 'aim (vector)'"
agent: "agent"
---
Add a new input action called **${input:actionName}** of type **${input:actionType}** (`button` or `vector`).

## Godot side

In the relevant game script under `mods-unpacked/KumaGee-VRCore/`, add a case to the `match input:` block inside the `_on_input` handler:

**If button (bool):**
```gdscript
"${input:actionName}":
    if value:
        # TODO: handle press
    # value is false on release — handle if needed
```

**If vector (Vector2):**
```gdscript
"${input:actionName}":
    # value is Vector2, axes normalized -1..1
    # TODO: apply direction
```

If the game script doesn't have a match block yet, create one following the pattern in `mods-unpacked/KumaGee-VRCore/whack-a-mole/whack_a_mole.gd`.

## Svelte web client side

In `game-client/src/lib/store.ts`, inside the `connectionStore`, add a method that calls the appropriate `webrtcClient` send helper:

**If button:**
```typescript
send${input:actionName|capitalize}(pressed: boolean) {
    connectionStore.sendInput("${input:actionName}", pressed);
},
```

**If vector:**
```typescript
send${input:actionName|capitalize}(x: number, y: number) {
    connectionStore.sendMove("${input:actionName}", { x, y });
},
```

Then wire it to a UI element in the appropriate Svelte component (e.g. a button in a route page or an event from `VirtualJoystick.svelte`).

## Protocol reminder

| Type | Wire format | GDScript `value` type |
|------|------------|----------------------|
| button | `"${input:actionName};1"` / `"${input:actionName};0"` | `bool` |
| vector | `"${input:actionName};x;y"` | `Vector2` |

`GameClient._process` parses this automatically — no changes needed to `game_client.gd`.

## Constraints

- Do not change the wire format or `GameClient` parsing logic.
