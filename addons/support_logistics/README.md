# Support Logistics

`jmfsb_support_logistics`

Logistics for TAC//SUPPORT (user, 2026-11-01: "add a logistic to support based
on simplexs"): the requester orders items from a **catalog**, clicks the
**delivery point** on the map and picks **AIRDROP** or **SLING LOAD**. One
asset per placed module. A provider of the support core (`addons/support`,
contract in its README) with kind `logi`; asset ids are `logi:<n>`, rows of
type `logistics` (the LOGISTICS tab). No module, no asset.

**Modelled on Simplex Support Services' logistics; no code of it used**
(GPL-2 against this mod's APL-SA - a behaviour reference only, never a
dependency): airdrop and slingload, the reference area as the catalog,
capacity, item cooldown, opening and unload heights, markings on what lands;
since 2026-11-05 its method for the flying too - the airdrop run-in with the
stick centred on the point, the sling set-down by a scripted hover that puts
the load on the ground, a recall that carries the load home, a crash-landed
airframe counted lost (user: "the back end should be based on simplex").
Simplex's station (depot) is not done; neither its stock per item, its
auto-fill of a crate from what the squad carries, nor its mass override for
a load heavier than the hook takes.

It is also the old **JMSB - Logistics Drop**, which moved here from
`support_air` (below).

## Modules

All in **JMSB Modules** (`jmfsb_modules`). No side attribute: the players'
side comes from the slots (D59).

| Module | What it is |
|---|---|
| JMSB - Logistics | One asset: the aircraft, methods, capacity, heights, timings, PAC crates, marking |
| JMSB - Logistics Catalog | An area (and anything synced to it) whose objects are what can be ordered; sync it to one or more JMSB - Logistics |
| JMSB - Logistics Drop (old) | `jmfsb_support_air_moduleLogistics`, hidden; read as a JMSB - Logistics (below) |

**JMSB - Logistics** attributes: aircraft class (blank: the side's vanilla
heavy helicopter, `B_Heli_Transport_03_unarmed_F` /
`O_Heli_Transport_04_covered_F` / `I_Heli_Transport_02_F`); callsign; Method:
Airdrop / Sling Load; Capacity (items per order); Sling Fulfillment (one
helicopter, or one per item); Drop Height; Chute Opens At (-1 at once);
Unload Height (how high over the point the sling load hangs in the hover
before it is lowered to the ground, at least 5 m - clearance of what stands
round the point); Cooldown and Item Cooldown; Respawns (default 0, -1
unlimited); Respawn Delay; Cooldown Starts; Crate Class, PAC Arsenal Lists,
Magazines / Other Gear Per Class; Marking; Fixed-Wing / Rotary Escort Class.
No CBA setting.

**Virtual until tasked** (user, 2026-11-02: "all support aircraft needs to be
virtual till tasked, then they spawn in at alt over the support module
location"; built, not seen in game). No aircraft exists until a delivery is
accepted. Then, at once, every aircraft of it is made in the air over the
module at its flight height, engines on and flying (the support core's
`spawnAirborne`, clear of any other aircraft there), flies the delivery,
flies back to the module and is removed there - crew and airframe, no wreck,
its escorts with it. **Spawn Distance** and **Response Delay** are retired
(a mission that set them still loads; the values are not read): the ETA is
the flight from the module at cruise speed. The old Logistics Drop's
Response Delay and the old Drone Escorts on/off go the same way.

**Respawns** (user, 2026-11-02: "make sure there is a respawn count for each
support, default no respawns"; virtual until tasked the same day; built, not
seen in game). Respawns is how many replacements the asset has for aircraft
**lost** (shot down or destroyed - each helicopter of a sling delivery
counts). A delivery that goes home and is removed over the module uses
none and sets no wait - only the cooldown. A loss with one left uses it: the
row reads REPLACING for the Respawn Delay, then the next delivery can fly. A
loss with none left: when the delivery ends the asset is gone - off the
SUPPORT list and the TO picker, and a card to its box, or a board order,
answers `UNABLE - NO AIRFRAME`. -1 unlimited. Reach card, verdict and SITREP
read `n SPARE AIRFRAMES` / `1 SPARE AIRFRAME` / `LAST AIRFRAME`. One that set
Respawn Delay -1 waits no time.

SLING LOAD is offered only for a helicopter with a cargo hook
(`slingLoadMaxCargoMass`); a module that ticks only SLING for anything else
airdrops, with an RPT warning.

## The catalog

Built once on the server at mission start (`fnc_moduleLogistics`) and
published on the module:

1. **Every item of every synced JMSB - Logistics Catalog**
   (`fnc_catalogRead`): each vehicle, crate or other object inside its area
   or synced to it. Not items: units, animals, logics, crewed vehicles, dead
   objects. Identical objects (same class, inventory and paint) are one item.
2. **One supply crate per PAC load** in PAC Arsenal Lists (`;` between
   loads), named `CRATE - <LISTS>`, packed at launch (`fnc_fillCrate`): the
   classes on its PAC arsenal lists (`list` from the common arsenal,
   `version.list` from a named version) plus the mission's `Common_Arsenal`
   list of the same name; nothing found keeps the crate class's own contents.
3. Neither: one crate of the Crate Class with its own contents.

**A reference keeps what it was placed with** (`fnc_catalogEntry`): its
weapons, magazines, items and backpacks in cargo at mission start (Eden's
Equipment Storage, or the class's own load), and a vehicle's paint and parts
(`BIS_fnc_getVehicleCustomization`). A delivery is cleared and refilled with
exactly that (`fnc_spawnItem`), so an emptied box arrives empty. Not kept:
weapon attachments, what is inside a backpack in cargo, ACE cargo, fuel and
damage. Its mass is read off the reference for the sling check.

The catalog module's **Remove The Objects** (on by default) deletes what it
read: the area is a shelf. One catalog may feed several logistics modules.

## Ordering (parameter slots 27, 47, 49-51)

| Slot | Stepper | Tasks |
|---|---|---|
| 49 | CART - `[[catalog index, count], ...]`, the real shape (the v2 board's cart); read first when it holds a pair | both |
| 50 | ITEM - list stepper over the catalog names (SLING walks only what the hook lifts) | both |
| 51 | COUNT - 1 to Capacity (1 for a one-helicopter sling) | both |
| 27 | DROP HEIGHT (MODULE, 150 ... 600 m) - from support_air | AIRDROP |
| 47 | MARKING (MODULE, SMOKE, IR STROBE, CHEMLIGHT, FLARE, NONE) - was CRATE SIGNAL | both |

Without a cart, ITEM and COUNT are a cart of one (`fnc_readCart`). The
delivery point is the task's own point, required. Slot 46 (support_air's
CONTENTS) is retired: a PAC load is a catalog item now.

The order is checked on the requester's machine and again on the server
(`fnc_check`, review S6): his side's asset, idle and not spent, a method it
flies, a point, a cart with something in it, no more than the Capacity, and
for SLING every item with sling points and no heavier than the hook takes.
The verdict before CONFIRM is the same check plus the ETA:
`ETA 4 MIN - 2 x HUNTER, 1 x CRATE - MAGAZINES (3/4) - LAST AIRFRAME`.

## How it flies

- **Where from and back to.** The module is the airbase (user, 2026-11-02:
  virtual until tasked): every aircraft is made over it when the delivery is
  accepted (`fnc_spawnAircraft`) and removed over it, within 600 m, when it
  is home - or where it is if it has not got there 30 min after it turned
  for home. Aircraft are CARELESS, weapons held, driver locked, and ALiVE is
  told to leave them alone through `adapter_alive` (as support_air does);
  delivered vehicles too.
- **Tactical flight** (user, 2026-11-01; the support core's README,
  "Tactical flight"). Lights only within 1500 m of the module; dark
  everywhere else, and the crew is kept from switching lights on. Helicopters
  fly nap of the earth (30 m), a sling helicopter higher by its rope, its
  load and 10 m while the load is on the hook; a plane at 4000 m ATL. The
  Sling Flight Height attribute is retired (a mission that set it still
  loads; the value is not read).
- **AIRDROP** (the run-in on Simplex's method, 2026-11-05). One aircraft is
  made over the module at the height for its distance from the point - its
  transit height far out (30 m a helicopter, 4000 m a plane) - carries the
  cart in on a straight line through the point and comes onto the Drop
  Height on the way in (from 5 m flown per m of height to change, no less
  than 1 km out; the height is given to the AI only when it changes, so the
  shared controller's climb of a stuck helicopter is left alone), flies 2 km
  on past the point, then back to its transit height and home to the module,
  where it is removed. The release point is two seconds' flying and 80 m
  short of the point **plus half the stick's length**, so the middle of the
  stick - one item a second - lands on the point, not its first item
  (Simplex moves its release back by half the stick the same way). Each item
  leaves from behind the tail with the aircraft's velocity, under a cargo
  chute (`jmfsb_common_fnc_addParachuteToObject`). Chute Opens At above 0:
  vehicles and physics objects fall free to that height first; anything the
  engine does not simulate opens at once. RPT: where the first item left,
  how fast and how high, how long the stick is.
- **SLING LOAD** (the set-down on Simplex's method, 2026-11-05: the load is
  put on the ground by a scripted hover and let go there - not cut from a
  height by the AI). One helicopter per item (Sling Fulfillment: one per
  item, up to the Capacity), made over the module side by side 60 m apart
  (the core's separation moves any that would be made inside another
  aircraft), each with its item on the hook from the start, nap of the earth
  plus the rope and the load (given to the AI once, again only when it
  changes). 200 m out support_air's flight control takes the airframe
  (`jmfsb_support_air_fnc_heliTake`, the one that lands every transport): no
  faster than 12 m/s to a hover with the load the **Unload Height** over its
  own set-down point's surface (60 m from the next; a roof or a deck counts,
  the load itself is looked past); in it (6 m across, 4 m up or down) it is
  taken again down to a hover with the load resting on the ground - its
  underside within 1.5 m of the surface, or touching it - and the hook is let
  go. Not down 90 s after the take, the load is let go where it hangs, its
  landing watched, with an RPT warning. Then the order home takes the
  airframe off the control and it flies to the module nap of the earth and
  is removed there. RPT: the take, the hover reached, the set-down (or the
  cut), each with the seconds since the take.
- **Drone Escorts** (user, 2026-11-02: "drone escorts is based on lz security
  for helos and always for fix wings"; support_air's `escortLaunch`, the
  support core's "Drone escorts"). Two drone wingmen with the delivery's
  **first** aircraft, made beside it over the module: a **plane always** takes
  two of the **Fixed-Wing Escort Class** (empty: the side's vanilla UCAV,
  `B_` / `O_` / `I_UAV_02_dynamicLoadout_F`); a **helicopter** two of the
  **Rotary Escort Class** only when the request's LZ security is YELLOW or RED
  - the `resupply` card has no security line, so a sling or helicopter
  airdrop goes unescorted; an empty rotary class is none. The Drone Escorts
  on/off attribute is retired (a mission that set it still loads; not read).
  They fly dark at their kind's height on its route, engage what threatens it
  and what is round the drop, put out flares when a missile is fired at it or
  them, and are removed with it over the module (`fnc_aircraftDone`); its
  other sling helicopters fly unescorted, and the escorts go when the first
  one is done. A lost lead sends them home alone; lost escorts are not
  replaced. A class not in the mission or the wrong kind: no escort, one RPT
  warning.
- **What lands** sets off its marking on the ground (`fnc_markItem`).
- **RTB** recalls it: in the air what is still aboard or on the hook is not
  delivered, and it flies home to the module and is removed. A sling load
  stays on the hook and is removed with the airframe over the module
  (2026-11-05, Simplex's abort carries it back; before, it was deleted in
  mid-air in front of the section).
- **Losses.** A lost aircraft's load is not delivered. It uses a respawn
  (Respawns, above): none left and the asset is gone when the delivery ends;
  otherwise REPLACING for the Respawn Delay. Lost is shot down, or down on
  the ground and unable to move (2026-11-05, Simplex's commission watch
  counts a crash-landing as killed): counted once, the airframe left where
  it is, its escorts recovered, said in the RPT. Before, a crash-landed
  airframe sat until the 30 min sortie timeout.
- **Cooldown** at the end (or at the request): Cooldown plus Item Cooldown
  per item delivered (per item ordered when it starts at the request).

## Threads

The asset answers a thread filed to `B:SUPPORT:logi:<n>` (support README,
"Threads"), under its call sign: ON TASK at launch ("airborne with 2 x HUNTER,
inbound 045 782"), CLOSE when every item ordered is down or lost
("delivered 2 x HUNTER at 045 782", "delivered 1 of 2 ... - aircraft lost at
...", "nothing delivered - recalled"), CANTCO when it never launched
("stood down", "could not launch").

## Resupply messaged in TAC//MSG (2026-11-01)

`docs/DESIGN_SUPPORT_MESSAGING.md` step 7 (user, 2026-11-01: "per the doc i
want to use the messaging system to call ai support"). A card filed to the
box goes to `jmfsb_support_logistics_fnc_srvThread` (the support core's
`thread` hook; `side` and `reply` registered too). Built, not seen in game.

| Card | Field | The order |
|---|---|---|
| `resupply` | Item N, COUNT | the catalog item by name (`fnc_catalogFind`: the name in any case, else the one item whose name holds it or that it holds), COUNT 1 when empty; a name the catalog lacks: CANTCO `NO STORES <NAME>` |
| | DELIVERY POINT | the point; none - `NO TARGET LOCATION` |
| | METHOD | AIRDROP / SLING; none - the first the module flies; one it does not fly: `NO <METHOD>`. SLING only for what the hook lifts, and the capacity: the order check's own reason (`... CANNOT GO ON A HOOK`, `... IS TOO HEAVY ...`, `... TAKES n AT MOST ...`) |
| | MARKING + colour | the marking; a smoke or chemlight colour picks its class (`MARK_COLOURS`); empty - the module's |
| `airdrop` | - | a PARADROP since the report-card review (user, 2026-11-02, decision 3) - a transport's card: CANTCO `PARADROP IS A TRANSPORT CARD - SEND RESUPPLY`. Supplies by air are a `resupply` with METHOD AIRDROP; the TO picker no longer offers `airdrop` on a LOGI row |

**The items are picks of the pre-made crates** (user, 2026-11-02: "we have
pre made crates so the requested items should be a drop down of them"; built,
not seen in game). RESUPPLY's item fields are choices with `choicesFrom`
`logiCatalog`: the composer asks `jmfsb_support_logistics_fnc_catalogNames`
`[addressees]` (Public, client) for the picks - the catalog names of the
logistics asset on the TO line (its box `B:SUPPORT:logi:<n>`), or of every
logistics asset of the viewer's side with none there, read off what the server
already publishes on each module (`catalog`), in catalog order, each once. No
new network traffic. The server still matches the picked name with
`fnc_catalogFind`, so a crate only another asset carries is `NO STORES
<NAME>`. Each item keeps its COUNT.

Not read: `resupply` REMARKS. Since the review a COUNT left empty is 1 and an
empty METHOD the module's first (both were required), and the MARKING list is
the deck's one ground-to-air list - PANEL and OTHER, words this module has no
class for, are its own mark.

**The thread.** One `ROGER, WILCO - ETA m:ss - 2 x HUNTER - AIRDROP` (the
core folds its receipt into a WILCO this quick), WHEELS UP `INBOUND - ETA
m:ss` and ON TASK at the launch; on the way in the lead aircraft says INBOUND
`ETA m:ss - <grid>` every minute and a minute out `1 MIN OUT - POP SMOKE`
(FLASH, and the issuer's popup, upper right) - `fnc_inbound`, the support
core's words (user, 2026-11-01; built, not seen in game); then when the last item is down `PACKAGE AWAY - CONFIRM
RECEIPT` (received / notfound). RECEIVED: CLOSED `RECEIVED - delivered ...`;
NOT FOUND: every item sets off its marking again and CLOSED `NOT FOUND -
LANDED AT <grids>`; silent 3 min - `NO RESPONSE - HOLDING`, 5 min - CLOSED
`... - NO RESPONSE` (D9, the support core's `prompt`). The thread stays open
past the aircraft's exit for the answer. Nothing delivered: CLOSED with why,
no receipt. RTB / ABORT / CLOSE: launching - stood down (CANTCO); in the air -
recalled, CLOSED with what was delivered. Busy: `TASKED`.

## The old JMSB - Logistics Drop

Its class `jmfsb_support_air_moduleLogistics` is defined here with its old
attribute properties (`jmfsb_support_air_logistics*`), hidden from the editor
list (scope 1), so a mission that placed it loads with its settings.
`fnc_moduleLegacy` reads it into a JMSB - Logistics: Method Parachute is
AIRDROP and Sling is SLING LOAD (a sling it cannot fly airdrops, as before),
Drops are Respawns, one fewer (2026-11-02: 3 drops is 2 respawns - now
replacements for aircraft lost; 0, unlimited, is -1), its Response Delay is
retired with the new module's, and it keeps what it did - one crate per
delivery, flown from the module, one helicopter, no item cooldown. Its CONTENTS choice
is the ITEM stepper now. What changed for those missions: the asset id is
`logi:<n>` (was `air:<n>`), and a sling crate the hook refuses at launch is
left out rather than dropped by chute.

## Plumbing

Uses support_air's `moveTo` (a helicopter: its vehicle order, re-issued, no
group waypoint), `heliTake` (the sling hovers and the set-down - the order
home releases it), `sweep`, `flightTime`, `readParam`, `bool` and
`escortLaunch` (not copies) and `jmfsb_cas_fnc_fmtEta`. The delivery crew's
pilot leads its group and never goes looking for a fight (no TARGET,
AUTOTARGET or AUTOCOMBAT), as support_air's and Simplex's. Clients reach the server only by
`remoteExecCall` to `jmfsb_support_logistics_fnc_order`; the server reaches
the side by `jmfsb_support_logistics_fnc_sayLocal` (both on the whitelist in
docs/SETUP.md).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_messaging`
- `jmfsb_support`
- `jmfsb_support_air`
- `jmfsb_cas`
- `cba_xeh` _(external)_

## Ships

3 unit classes, 46 functions.

## Eden modules

### JMSB - Logistics

`jmfsb_support_logistics_module`, category jmfsb_modules

One taskable logistics asset: a TAC , , , , , , , , Method: ... - Airdrop and/or sling load Capacity - Items one order may hold Sling Fulfillment - One helicopter, or one per item Drop Height / Chute Opens At (m) - The airdrop pass and the chutes Unload Height (m) - The hover over the point before a sling load is lowered to the ground Cooldown / Item Cooldown (sec) - Time before the next delivery, plus per item Respawns - Replacements for aircraft lost; 0 none, -1 unlimited Respawn Delay (sec) - Time after a loss before the next delivery can fly Cooldown Starts - End of the delivery, or at the request Crate Class / PAC Arsenal Lists / Per Class - The PAC crates Marking - Smoke, IR strobe, chemlight, flare or none on what lands Fixed-Wing Escort Class - Two drone wingmen with a plane, always; empty for the side's vanilla UCAV Rotary Escort Class - Two drone wingmen with a helicopter when the LZ security is YELLOW or RED; empty for none

<details><summary>19 attributes</summary>

- `aircraftClass`
- `arsenalLists`
- `callsign`
- `capacity`
- `cooldown`
- `cooldownTrigger`
- `crateClass`
- `dropHeight`
- `escortHeli`
- `escortPlane`
- `fulfillment`
- `itemCooldown`
- `itemCount`
- `magCount`
- `openHeight`
- `respawnDelay`
- `respawns`
- `signal`
- `unloadHeight`

</details>

### JMSB - Logistics Catalog

`jmfsb_support_logistics_moduleCatalog`, category jmfsb_modules

What a JMSB - Logistics module can deliver. Sync this module to one or more of them.<br>Every vehicle, crate or other object inside the area, or synced to this module, is one item of the catalog - its editor inventory and paint go with it. Units and crewed vehicles are not items; identical objects are one item.<br>Remove The Objects - Clear the area once it is read

### JMSB - Logistics Drop (old)

`jmfsb_support_air_moduleLogistics`, category jmfsb_modules

Replaced by JMSB - Logistics (2026-11-01). Kept so missions that placed it still load: it becomes a JMSB - Logistics asset with a capacity of one crate, flown from the module.<br>Place JMSB - Logistics in new missions.

<details><summary>13 attributes</summary>

- `aircraftClass`
- `arsenalLists`
- `callsign`
- `cooldown`
- `cooldownTrigger`
- `crateClass`
- `dropHeight`
- `drops`
- `itemCount`
- `magCount`
- `method`
- `respawnDelay`
- `signal`

</details>

## Functions

<details><summary>46</summary>

- `jmfsb_support_logistics_fnc_account`
- `jmfsb_support_logistics_fnc_aircraftDone`
- `jmfsb_support_logistics_fnc_assetAvailable`
- `jmfsb_support_logistics_fnc_assets`
- `jmfsb_support_logistics_fnc_available`
- `jmfsb_support_logistics_fnc_cartNames`
- `jmfsb_support_logistics_fnc_catalogEntry`
- `jmfsb_support_logistics_fnc_catalogFind`
- `jmfsb_support_logistics_fnc_catalogNames`
- `jmfsb_support_logistics_fnc_catalogRead`
- `jmfsb_support_logistics_fnc_check`
- `jmfsb_support_logistics_fnc_countLine`
- `jmfsb_support_logistics_fnc_deliver`
- `jmfsb_support_logistics_fnc_dropTick`
- `jmfsb_support_logistics_fnc_entityRow`
- `jmfsb_support_logistics_fnc_eta`
- `jmfsb_support_logistics_fnc_fillCrate`
- `jmfsb_support_logistics_fnc_finish`
- `jmfsb_support_logistics_fnc_inbound`
- `jmfsb_support_logistics_fnc_launch`
- `jmfsb_support_logistics_fnc_logicOf`
- `jmfsb_support_logistics_fnc_lost`
- `jmfsb_support_logistics_fnc_markItem`
- `jmfsb_support_logistics_fnc_moduleCatalog`
- `jmfsb_support_logistics_fnc_moduleLegacy`
- `jmfsb_support_logistics_fnc_moduleLogistics`
- `jmfsb_support_logistics_fnc_order`
- `jmfsb_support_logistics_fnc_overlay`
- `jmfsb_support_logistics_fnc_preview`
- `jmfsb_support_logistics_fnc_reach`
- `jmfsb_support_logistics_fnc_readCart`
- `jmfsb_support_logistics_fnc_releaseItem`
- `jmfsb_support_logistics_fnc_say`
- `jmfsb_support_logistics_fnc_sayLocal`
- `jmfsb_support_logistics_fnc_side`
- `jmfsb_support_logistics_fnc_sitrep`
- `jmfsb_support_logistics_fnc_slingTick`
- `jmfsb_support_logistics_fnc_spawnAircraft`
- `jmfsb_support_logistics_fnc_spawnItem`
- `jmfsb_support_logistics_fnc_srvThread`
- `jmfsb_support_logistics_fnc_status`
- `jmfsb_support_logistics_fnc_task`
- `jmfsb_support_logistics_fnc_tasks`
- `jmfsb_support_logistics_fnc_threadReply`
- `jmfsb_support_logistics_fnc_threadState`
- `jmfsb_support_logistics_fnc_threadTimeout`

</details>
