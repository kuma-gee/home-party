# Game Design Document

VR Couch Party is a local party game using a single VR headset to play various
party games with your friends. Other players join the game using their phones
through a simple local website.

## Games

- [Castle Defense](./CASTLE_DEFENSE.md)
- [Draw & Guess](./DRAW_AND_Guess.md)
- [Ghost Hunter](./GHOST_HUNTER.md)

## Home World

The home world is a living room where the party lives. When the VR player puts
on the headset, they find themselves in a cozy virtual space surrounded by game
boxes on a shelf. This is the hub — the place to browse available games, see
what each one is about, pick one, and launch it for everyone to play.

The VR player can:

- **Look around** the space and see all the games laid out in front of them
- **Pick up any game box** to inspect what's inside — its name, description,
  and player count show up on a screen
- **Slot a game into the designated play zone** to lock in their choice
- **Press the big red button** on the TV remote to kick things off

Players on their phones (spectators) see the same game details mirrored on a
desktop screen, so everyone's on the same page before the game starts.

When a game ends, everyone returns here to pick the next one. The loop is
simple: arrive, browse, pick, play, repeat.

### Plushie Players

When mobile players join the lobby, they don't just spectate — they **spawn as
plushies** scattered around the living room. These are soft, grabable toys that
the VR player can pick up, squeeze, toss, or stack. Each plushie is a random
animal. The player numbers is shown as a tag around the animals neck. Mobile
players can click any button and the plushie will make a sound and some visual
cue for some basic interactions.

1. VR player arrives in the living room
2. Mobile players join and **pop in as plushies** on the couch/floor
3. VR player can **browse games** while also **tossing plushies** around
4. Mobile players **squeak and glow** to grab attention / react to game choices
5. VR player slots a game and presses start → loads game

**States**

- CONNECTED: player is connected and can join the games. The default state.
- UNPLAYABLE: for phone-only games, if a player is connected via controller.
  Show an icon on top of the plushie that they cannot join this specific game.
- DISCONNECTED: plushies gets removed from the game.

## Settings

### Quick Settings Menu

The VR player can open a quick settings menu at any time by **holding the B
button on the left controller**. The menu appears as a floating panel attached
to the left hand, **pauses the game**, and closes when pressed again.

| Option | Action |
|--------|--------|
| **Reset Space** | Re‑center VR playspace and reset floor height. Useful when the headset changes hands or drifts during a party. |
| **Settings** | Opens the full Settings panel (see below). |
| **Return Home** | Exit the current mini‑game and return to the hub living room. |

### Full Settings Panel

Opened from the Quick Settings menu. A modal panel for detailed adjustments.

| Section | Options |
|---------|---------|
| **Audio** | Master volume, SFX volume, Music volume, Voice volume sliders |
| **Graphics** | Quality preset slider (Low / Medium / High / Ultra), Render scale, Anti‑aliasing toggle, Foveated rendering toggle |
| **Controls** | Controller diagram showing all button mappings for the current context (hub or active mini‑game) |
| **Language** | Language selection dropdown (en, ja, zh, etc.) |

The panel closes with a **Back** button that returns to the Quick Settings
Menu.

## Mobile Players

Players can join the game via the phone browser which will give them a gamepad
replacement in most cases. But in some cases where gamepads aren't useable
(like Draw & Guess) will have a unique layout input for that.

It generally functions as a gamepad controller and thus shouldn't display data
or anything else on it. All the data and information will be visible in the
shared desktop screen.
