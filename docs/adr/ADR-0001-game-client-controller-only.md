# ADR-0001: Game-Client as Controller Replacement Only

- **Status:** Accepted
- **Date:** 2026-06-10

## Context

The game needs a way for mobile players to interact with mini-games during local VR parties. Since not all players own VR headsets, smartphones offer a natural input channel. An initial approach considered making the game-client a full second-screen experience — displaying scores, timers, hints, and other game data alongside input controls.

However, mini-games must also support standard gamepad controllers (e.g., Xbox/PlayStation controllers connected via Bluetooth). If the game-client displayed exclusive information or game state, smartphone users would have an asymmetric advantage over gamepad users, and game designers would have to maintain two separate presentation paths.

## Decision

The game-client acts exclusively as a **controller replacement** — a pure input device. It transmits button presses and joystick movements over a WebRTC data channel. No game state, scores, timers, hints, or any other information is displayed on the phone screen. All visual feedback for all players (VR, mobile, and gamepad) is shown on the shared desktop/TV screen.

**Exceptions:** A mini-game may opt out of gamepad support and use the game-client as a richer interface (e.g., Draw & Guess, where a phone touchscreen is needed for drawing). In those cases, gamepad controllers will not be usable for that mini-game.

## Consequences

- **Positive:** Gamepad and smartphone players have feature parity — no player gets more or less information based on their input device.
- **Positive:** The game-client remains lightweight and simple (SvelteKit with a single route, no game state management).
- **Positive:** Mini-game designers (including modders) only need one visual output path (the shared desktop view) and one simple input protocol, reducing duplication and making modding more accessible.
- **Negative:** Smartphone players cannot glance at their own phone for private information (e.g., a secret role or hand of cards) — such scenarios must be handled on the shared screen, in VR only, or require the mini-game to drop gamepad support and use an exception.

## Alternatives Considered

- **Full second-screen client:** The game-client would render scores, game state, hints, and other data alongside input controls. Rejected because gamepad controllers cannot do the same, creating an asymmetric experience, adding UI surface area for mini-game designers to maintain, and making mods more complex.
