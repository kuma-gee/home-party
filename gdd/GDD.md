# Game Design Document

VR Couch Party is a local party game using a single VR headset to play various
party games with your friends. Other players join the game using their phones
through a simple local website.

## Games

- [Castle Defense](./CASTLE_DEFENSE.md)
- [Draw & Guess](./DRAW_AND_Guess.md)

## Home World

The home world is a living room where the party lives. When the VR player puts on the headset, they find themselves in a cozy virtual space surrounded by game boxes on a shelf. This is the hub — the place to browse available games, see what each one is about, pick one, and launch it for everyone to play.

The VR player can:

- **Look around** the space and see all the games laid out in front of them
- **Pick up any game box** to inspect what's inside — its name, description, and player count show up on a screen
- **Slot a game into the designated play zone** to lock in their choice
- **Press the big "Start" button** or use the TV remote to kick things off
- **Take a break** — the pause menu lets them recenter their view, adjust settings, or head back to the hub

Players on their phones (spectators) see the same game details mirrored on a desktop screen, so everyone's on the same page before the game starts.

When a game ends, everyone returns here to pick the next one. The loop is simple: arrive, browse, pick, play, repeat.

### Plushie Players

When mobile players join the lobby, they don't just spectate — they **spawn as plushies** scattered around the living room.
These are soft, grabable toys that the VR player can pick up, squeeze, toss, or stack. Each plushie is a random animal.
The player numbers is shown as a tag around the animals neck. Mobile players can click any button and the plushie will
make a sound and some visual cue for some basic interactions.

1. VR player arrives in the living room
2. Mobile players join and **pop in as plushies** on the couch/floor
3. VR player can **browse games** while also **tossing plushies** around
4. Mobile players **squeak and glow** to grab attention / react to game choices
5. VR player slots a game and presses start → loads game

**States**

- CONNECTED: player is connected and can join the games. The default state.
- UNPLAYABLE: for phone-only games, if a player is connected via controller. Show an icon on top of the plushie that they cannot join this specific game.
- DISCONNECTED: plushies become gray and the player number tag becomes a disconnected icon. Physics still all work. Player can reconnect to restore the state
