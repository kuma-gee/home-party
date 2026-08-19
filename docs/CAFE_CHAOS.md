# Café Chaos

A cooperative coffee-shop management game in the spirit of Overcooked. The VR
player runs the espresso machine and milk steamer with their physical hands while
up to two mobile players control kitchen runners on the shared screen. Everyone
works together to prepare and serve drink orders to a queue of impatient
customers before the shift ends.

- **Players:** 2–3 (1 VR + up to 2 mobile)
- **Win Condition:** Cooperative — serve drink orders before the shift ends
- **Shift Time:** 3 minutes
- **Recommended Players:** 3

## Design Pillars

1. **Shared kitchen, split perspectives** — VR player is first-person at the
   machines; mobile runners are top-down on the shared screen. Both views show the
   *same* kitchen, so everyone sees each other working.
2. **Roles emerge from space, not rules** — No hard role locks. The espresso
   machine and steamer are VR-only stations, and the pantry/serving counter are far
   from them. Interdependence comes from physical distance plus VR-only stations,
   exactly like Overcooked's spatial bottlenecks.
3. **Physical craft** — The VR player's stations demand real hand gestures (tamp,
   pull a lever, tilt a pitcher). Skill lives in the hands, not just timing bars.
4. **Escalating chaos** — Recipes grow more complex as the shift progresses, and
   customer patience tightens. Communication is the real game.

## The Kitchen

A single 3D kitchen shared by all players. Layout (described top-down):

| Zone | Position | Purpose |
|------|----------|---------|
| **Pantry shelves** | Back-left wall | Ingredient pickup: beans, milk, syrups, cups |
| **Grinder + Espresso machine** | Center | Brew espresso shots (VR-only station) |
| **Milk steamer** | Center-right | Steam / froth milk (VR-only station) |
| **Pass counter** | Between machines and front | Neutral surface for handing items between players |
| **Serving counter** | Front, facing customers | Deliver finished drinks |
| **Trash bin** | Corner | Discard ruined drinks and spent ingredients |

The VR player physically stands at the machine cluster (center). Mobile runners
move across the full kitchen on the shared screen, shuttling between the pantry
(back-left) and the serving counter (front).

### Pass Counter

A waist-height surface both sides can reach. The VR player places finished drinks
and spent pitchers here; mobile runners deposit ingredients here for the VR player
to grab. Any item on the pass counter is grabbable by the VR player's hands and
pickable by a mobile runner. This is the coordination nexus — no hand-off animation
needed, just place-and-grab.

## Recipes

A drink is a **cup** plus a set of **components**. Components may be added in any
order, but the cup must contain *exactly* the required set — adding a wrong or
extra component ruins the drink and it must be trashed.

### Components

| Component | Source | Station |
|-----------|--------|---------|
| Espresso shot | Grind beans → pull shot | Espresso machine (VR) |
| Steamed milk | Heat milk, no foam | Milk steamer (VR) |
| Milk foam | Heat milk, tilt for foam | Milk steamer (VR) |
| Hot water | Dispenser | Hot water tap (anyone) |
| Syrup (chocolate / vanilla / caramel) | Squeeze bottle | Syrup rack (VR pours, or mobile squirts) |

### Drink Table

| Drink | Components | Patience |
|-------|-----------|----------|
| Espresso | cup + espresso shot | 45s |
| Drip Coffee | cup + espresso shot + hot water | 45s |
| Americano | cup + espresso shot + hot water + hot water | 50s |
| Latte | cup + espresso shot + steamed milk | 55s |
| Cappuccino | cup + espresso shot + steamed milk + milk foam | 60s |
| Mocha | cup + espresso shot + steamed milk + chocolate syrup | 65s |
| Caramel Latte | cup + espresso shot + steamed milk + caramel syrup | 75s |

**Design Intent:** Early orders are espresso/drip — quick, single-station, teaching
the loop. Latte/cappuccino force the espresso→steam→pour sequence. Mocha and
caramel add the syrup step and split a player's attention. Complexity ramps with
steps, not ingredient volume, so the *number of touch points* is the real cost.

### Quality & Timing

Espresso and milk have a quality window — overcooking ruins the component:

- **Espresso:** after pulling the shot, the shot is *good* for ~6s. Leave it longer
  and it over-extracts (bitter) → ruined. The VR player must pour it into the cup
  promptly.
- **Milk:** steamed milk overheats. Stop steaming when the audible pitch hits the
  sweet spot; keep steaming and it scorches → ruined. Foam amount (latte vs
  cappuccino) is controlled by pitcher angle while steaming.
- **Syrup / water:** no timing risk, just correctness.

A ruined component must go in the trash; a ruined cup is discarded and a fresh cup
is grabbed from the pantry.

## VR Player — Barista

First-person at the machine cluster. Runs the espresso machine and milk steamer,
pours drinks, and can reach the pass counter from a standing position.

### Controls

| Action | Input |
|--------|-------|
| Move | Left thumbstick (smooth locomotion) |
| Turn | Right thumbstick (snap) |
| Grab / release item | Grip button (both hands, `XRToolsPickable`) |
| Interact / pour | Trigger (context-dependent) |

### Espresso Machine

A multi-step, all-hands process:

1. **Grab portafilter** from the machine.
2. **Fill** — hold the portafilter under the grinder dispenser and press trigger;
   the grinder doses grounds (auto-tamps visually).
3. **Lock in** — place the portafilter into the group head and twist (physical
   rotation gesture) to lock.
4. **Pull the shot** — grab the lever and pull it down; espresso pours into any cup
   placed on the drip tray beneath.
5. **Pour promptly** — the shot is good for ~6s, then over-extracts and is ruined.

### Milk Steamer

1. **Grab pitcher**, place under the wand.
2. **Hold the trigger** to steam; an audible pitch rises as milk heats.
3. **Tilt the pitcher** (controller angle) to introduce air → foam. Flat = steamed
   milk, angled = foam.
4. **Stop at the sweet spot** — past it, the milk scorches and is ruined.

### Pouring

- Tilt a full cup/pitcher over a target cup to pour; the game resolves which
  component pours based on the source vessel's contents.
- Squeeze syrup bottles with the trigger over a cup to add syrup.

**Design Intent:** The VR player is the craft bottleneck by design — the espresso
machine and steamer are the only stations with physical gestures *and* quality
timers. This makes the VR role feel like the center of the kitchen while forcing
them to trust the runners for logistics, not do everything themselves.

## Mobile Players — Runners

Each mobile player controls one kitchen runner on the shared top-down screen. They
handle logistics: fetch ingredients, deliver to the pass counter, and carry
finished drinks to the serving counter.

### Controls

Uses the generic gamepad controller layout.

| Action | Input |
|--------|-------|
| Move | Left joystick |
| Pick up / interact / place | Button A |
| Drop / cancel | Button B |

### Runner Tasks

- **Fetch** — walk to the pantry shelf, press **A** to pick up an item (beans, milk,
  syrup, cup). One item carried at a time.
- **Deposit** — carry the item to the pass counter and press **A** to place it for
  the VR player to grab.
- **Serve** — pick up a finished drink from the pass counter, carry it to the
  serving counter, press **A** to hand it to the customer.
- **Syrup** — runners may squirt syrup directly into a cup themselves (press **A**
  while holding the bottle near a cup), giving the team a second syrup path when
  the VR player is swamped.
- **Trash** — carry ruined cups to the trash bin and press **A** to discard.

**Design Intent:** The runner role is all movement and route planning — the
Overcooked "shuttle" fantasy. Because they're the only ones who can move across
the full kitchen quickly, the team lives or dies on how well they anticipate what
the barista needs next.

## Orders & Customers

Customers arrive at the serving counter in a queue, each with an order bubble
showing the drink's icon + recipe. Each order has a **patience meter** that drains
from the moment the customer arrives.

- **Served on time** — the customer is satisfied and leaves happy.
- **Patience hits zero** — customer storms out; the order is failed.
- **Wrong drink served** — the drink is trashed and the customer's patience keeps
  draining (no direct penalty, but time is lost).

**Order escalation** — the first ~45s serves only espresso/drip/americano. Latte and
cappuccino enter the pool after that; mocha and caramel appear in the final third of
the shift. The queue depth (1–3 customers waiting) also grows as the shift
progresses, so the team is always juggling multiple orders by the end.

## Round Flow

1. **Prepare (5s)** — Players are placed: VR player at the machine cluster, runners
   at the pantry. A "Get Ready!" banner shows.
2. **Shift (3 min)** — Orders arrive, players cook and serve.
3. **End** — When the timer expires, the shift ends.

## Shared Screen & HUD

The shared desktop view shows the top-down kitchen plus a lightweight HUD. Mobile
phones remain controller-only — no game data on the phone.

| Element | Description |
|---------|-------------|
| Kitchen view | Top-down camera of the whole kitchen |
| Order tickets | Queue of active orders with patience bars |
| Timer | 3:00 shift countdown |

The VR player sees the same order tickets floating in-world near the pass counter,
so both sides read orders from a shared, consistent source.

## Future Considerations

> **Dirty cups / sink:** a dishwashing loop (used cups must be washed before
> reuse) is a natural Overcooked-style pressure valve but adds a fourth station and
> a runner-only chore. Parked to keep the first version tight.
>
> **Multi-shift campaign:** successive shifts with a shared day timer and more
> machines (a second espresso machine, a tea kettle) would extend the loop into a
> short campaign. Parked; single-shift is the party-game target.
>
> **Runner trays:** letting runners carry 2–3 items on a tray would raise the
> skill ceiling and lower shuttle tedium. Parked behind playtesting the 1-item
> rule first.
