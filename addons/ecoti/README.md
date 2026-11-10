# ECOTI

`jmfsb_ecoti`

Enhanced Clip-On Thermal Imager. A thermal overlay fused onto the image
intensifier: through an NVG that carries it, people, vehicles and animals in
the thermal window are drawn as boxes in the colour of what they are - blue
your faction, green your side, red armed, white civilian, yellow unknown -
while the rest of the picture stays the goggle's own. Boxes only: no glow, no
heat blob, no ring round the window and no HUD (users, 2026-10-15 and -17).
Client-side only;
nothing is sent over the network, so it works the same in single player, hosted
and on a dedicated server. The LZs and DZs it rings (2026-11-02) are the one
thing it reads from the server, as the support core publishes them.

## The AiTR goggles

The NVG is the AiTR device. Any opted-in NVG draws ECOTI in **NVG mode**; one
that also says `jmfsb_ecoti_day = 1` draws it in **day mode** too - the AiTR
goggles (user, 2026-10-17: "work with or without nvg's"), JMSB NVG-slot versions
of 21 JCA and SOF tactical goggles with night vision, thermal and full screen,
built by `tools/gen_aitr_goggles.py` into `compatibility/aitr_goggles_jca` and
`aitr_goggles_sof`. Nothing draws in thermal, which already shows heat.

## Which goggles

An NVG opts in with one config line:

```cpp
jmfsb_ecoti_enabled = 1;
```

Every MIG goggle gets it from `tools/gen_mig.py` (`NVG_THERMAL`). Any other NVG
class - ours or a compat patch - is opted in the same way. Nothing else carries
it, and there is no setting for it: which goggles have the clip-on is a fact
about the goggle.

## When it is on

All of these, every frame - the moment one fails, the overlay and the HUD go:

- AiTR is enabled - *Enable AiTR*, each player's own setting, on by default (user, 2026-10-17)

- the clip-on is powered (**Ctrl + Shift + N**, on by default; a hint says which)
- the player is alive and is the camera, on foot or in his own vehicle
- Zeus is not open - opening it turns ECOTI off, closing it brings it back
- the map is not open - opening it hides the boxes, closing it brings them back (user, 2026-10-17)
- no dialog is open - the tablet or any other dialog hides the boxes and the compass. The hide runs on
  EachFrame, not in the Draw3D handler: Arma stops calling Draw3D while the map is up, so a hide there
  left the last boxes on screen over the map and the tablet (user, 2026-10-20)
- he is wearing an opted-in NVG in **NVG mode** - or in day mode too when it says `jmfsb_ecoti_day = 1` (never TI)

## How far it reaches

Four ranges, each a player setting (user, 2026-10-24): **AI on foot 100 m**,
**players on foot 250 m**, **vehicles and animals 250 m** - and **750 m for
everything while he looks through a Vector** (the [JMSB] Vector Designator,
or any ACE Vector: raised, in its optics, on foot). A target fades from the
full-contrast distance to its own range.

## What it draws

**One box per target** - every man, vehicle and animal in sensor range, in the
colour of what it is. Boxes, never traced outlines: the outlines (limb-by-limb
from the skeleton, then merged rims) took the game from 50+ to under 10 FPS on
2026-10-17, and the user's word was "boxes would work". A box is four flat
strips, so a target costs the same whatever it is.

| Colour | Is |
| --- | --- |
| blue | your own faction (*Own faction colour*) |
| green | another faction on your side or a friendly one (*Same side colour*) |
| red | hostile to your side, or a civilian with a weapon (*Armed colour*) |
| white | an unarmed civilian |
| yellow | unknown - an empty vehicle, an animal, anyone of no side |

**AiTR labels** (client setting, on by default) sit under each box, the way an
aided-target-recognition display reads: what it is, one thing about it, and
its range - `PERSON | ARMED | 240 m`, `VEHICLE | TANK | 1.2 km`. The classes
are PERSON (ARMED / UNARMED / SURRENDER), VEHICLE (TANK / APC / TRUCK / CAR /
STATIC), VESSEL, UAS and AIRCRAFT (MULTICOPTER or HELICOPTER / FIXED-WING) and
ANIMAL.

**The net card** (user, 2026-10-17). Under the AiTR line of a friendly player
**on the net** - your faction or side, with his radio published to the
TAC//PAD - four more lines:

```
SGT Reyes | MED                  rank, name and role
OVERLORD 6 1                     his squad (group callsign)
WIA 64% | CH 3 - GHOST | NET C2   health, channel, active net
ACE  A C E                       his ACE report, each letter coloured
```

Rank and role names, the health test, the channel and the ACE report are the
TAC//PAD squad page's own, so the card and the table never disagree. The
last field is ECOTI's: game voice has no frequency, so each player publishes
his own active net, `NET C2`, only when it changes. The ACRE frequency it read
before was removed on 2026-10-31 (DEC1). Without the TAC//PAD nobody is on the net and there are no cards.

Hostile is `getFriend` below 0.6 from the player's side. A vehicle is what its
commander is, and red if any civilian aboard is armed. Colour is worked out
twice a second, not per frame.

**A man's box** runs from his feet to just past his eyes (`eyePos`), so a
crouched man is shorter by as much as his eyes are lower; prone it lies along
the ground, back from his eyes the way he faces. **A vehicle's or animal's** is
round its bounding box. Both are square to the screen. Contrast is full out to
*full contrast distance* and falls to the sensor range.

**Only what can be seen.** Each target is line-of-sight checked against the
VIEW LOD from the player's eyes to several body points, and the best one wins:
behind a wall is nothing at all; in a bush he is boxed while enough of him
shows.

**Inside the window only.** A box is drawn whole inside the round window or not
at all. **Full screen is full screen**: under a JMSB goggle
(`jmfsb_nvg_fullScreen = 1`) with the player's *NVG full screen* setting on
(`jmfsb_nvg`) there is no tube and so no window - boxes anywhere on screen
(user, 2026-10-17). Through ACE's tube mask the window stays round.

**The boxes are UI controls** on the mission display, not 3D icons: a
rectangle snapped to whole pixels with its four sides laid inside it edge to
edge, so the corners meet (user, 2026-10-17: the `drawIcon3D` strips were "4
lines that do not line up"). *Box line width* is in screen pixels. At most 48
boxes are drawn in one frame.

**Line of sight only** (user, 2026-10-17). A box shows only while the player
can see the target, and goes at the next re-check (0.2 s) after he cannot -
nothing is held on screen. Against flicker it appears once 15% of the target
shows and goes below 5%, so a ray grazing a leaf edge does not blink it. A
box's brightness is its range only.

## Compass

A DUI-style line compass across the top centre of the screen (user,
2026-10-19), shown exactly when the boxes could be - AiTR on, no dialog over
it - whether or not anything is in range, and only with *Show AiTR compass*
(each player's own setting, on by default). A tick every 5 degrees, a label
every 15 (N, NE, E... by name, the rest as bearings), fading toward the ends;
at the centre a marker and the three-digit heading the camera faces, both in
the TAC//PAD colour scheme's accent (white without the TAC//PAD). Like the
boxes it is controls on the mission display, drawn from the same Draw3D.

## LZs and DZs (2026-11-02)

User, 2026-11-02: "in AiTR lz and drop zones need to be highlighted". Built,
not seen in game.

The open landing and drop zones of your side's support requests, as the
server publishes them (`jmfsb_support`, "The active LZs and DZs"). Each is a
ring of 24 dots on the ground at the zone's radius, and under it a label in
the AiTR style:

```
LZ | PICKUP | RAVEN | 1.2 km
LZ | INSERT | RAVEN | 800 m
LZ | EXTRACT | ...    LZ | CASEVAC | ...    LZ | DEST | ...    LZ | QRF | ...
DZ | PARA | ...    DZ | QRF | ...    DZ | STATIC / HALO / HAHO | SKYTRAIN | 3.4 km
DZ | RELEASE | ...    DROP | RESUPPLY | ...    DROP | SLING | ...
```

The call sign is left out when it is longer than 12 letters. Dots and label
are in the TAC//PAD accent, white without the TAC//PAD, as the compass.

- **Any range, no line of sight.** It is a nav aid, not a sighting.
- **Same rules as the boxes otherwise.** Only while AiTR is drawing (see "When
  it is on"); the map, a dialog or Zeus hides it. Inside the round window only,
  unless full screen. A dot or label off the screen is not drawn. The label
  shows while the zone's centre is in view.
- **At most 6 zones**, the nearest.
- *AiTR LZ / DZ highlight* - each player's own setting, on by default. Off:
  no zones.

Cost: the list is read and each ring worked out twice a second, only when it
changed; Draw3D only projects the 24 dots and the centre of each zone.

## Cost

One Draw3D handler that draws from caches only - three projections and five
pooled controls moved per target in view. Who is in range is rebuilt
twice a second; line of sight is re-checked in four slices, so each target is
refreshed every 0.2 s and no frame checks them all.

## Building marks

A marked building gets a box in its colour, with its label and range, out to
2 km and through walls (user, 2026-11-06). Three ways to mark one:

- **Eden or Zeus:** the JMSB - AiTR Building Mark module, with a Colour and a
  Label. It marks the buildings synced to it, else the nearest within 25 m.
- **Zeus with ZEN:** the AiTR building mark module asks the colour and the
  label in a dialog. CLEAR takes a mark off.
- **Players:** the AiTR - mark building key, unbound by default. It takes the
  building under the crosshair and asks the colour on numpad 6-9 on the phone
  or side device. Numpad 0 / . pages, and CLEAR shows when it is marked.
  With no device up, each press steps to the next colour.

The server keeps the list and every player sees the same marks.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_main` _(external)_
- `cba_xeh` _(external)_

## Ships

1 unit class, 31 functions.

## Eden modules

### JMSB - AiTR Building Mark

`jmfsb_ecoti_moduleMark`, category jmfsb_modules

Marks a building for every AiTR (ECOTI): a box round it in the Colour, the Label and range under it, out to 2 km, through walls.<br>Place it on the building, or sync buildings to it. Nothing synced: the nearest building within 25 m.<br>Players mark from their own key (AiTR - mark building) and pick the colour on numpad 6-9 on the phone or side device. A Zeus with ZEN has a dialog: 1st Joint Multi-Functional Strike Battalion > AiTR building mark.

<details><summary>2 attributes</summary>

- `colour`
- `label`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_ecoti_aitr` | CHECKBOX | Enable AiTR |
| `jmfsb_ecoti_rangeAi` | SLIDER | Range: AI on foot (m) |
| `jmfsb_ecoti_rangePlayer` | SLIDER | Range: players on foot (m) |
| `jmfsb_ecoti_rangeVehicle` | SLIDER | Range: vehicles and animals (m) |
| `jmfsb_ecoti_rangeVector` | SLIDER | Range through a Vector (m) |
| `jmfsb_ecoti_hideNear` | CHECKBOX | Hide close boxes |
| `jmfsb_ecoti_hideNearDistance` | SLIDER | Hide close boxes inside (m) |
| `jmfsb_ecoti_windowSize` | SLIDER | Thermal window size |
| `jmfsb_ecoti_nearDistance` | SLIDER | Full contrast distance (m) |
| `jmfsb_ecoti_lineWidth` | SLIDER | Box line width (px) |
| `jmfsb_ecoti_colorPlayer` | COLOR | Own faction colour |
| `jmfsb_ecoti_colorFriendly` | COLOR | Same side colour |
| `jmfsb_ecoti_colorEnemy` | COLOR | Armed colour |
| `jmfsb_ecoti_labels` | CHECKBOX | AiTR labels |
| `jmfsb_ecoti_zoneHighlight` | CHECKBOX | AiTR LZ / DZ highlight |

## Functions

<details><summary>31</summary>

- `jmfsb_ecoti_fnc_boxRect`
- `jmfsb_ecoti_fnc_buildingBox`
- `jmfsb_ecoti_fnc_draw`
- `jmfsb_ecoti_fnc_drawBoxes`
- `jmfsb_ecoti_fnc_drawCompass`
- `jmfsb_ecoti_fnc_drawZones`
- `jmfsb_ecoti_fnc_hideCovered`
- `jmfsb_ecoti_fnc_isActive`
- `jmfsb_ecoti_fnc_isFullScreen`
- `jmfsb_ecoti_fnc_labelText`
- `jmfsb_ecoti_fnc_manBox`
- `jmfsb_ecoti_fnc_markKey`
- `jmfsb_ecoti_fnc_markPick`
- `jmfsb_ecoti_fnc_markPublish`
- `jmfsb_ecoti_fnc_markSet`
- `jmfsb_ecoti_fnc_markTarget`
- `jmfsb_ecoti_fnc_moduleMark`
- `jmfsb_ecoti_fnc_publishFreq`
- `jmfsb_ecoti_fnc_rangeText`
- `jmfsb_ecoti_fnc_targetCard`
- `jmfsb_ecoti_fnc_targetColour`
- `jmfsb_ecoti_fnc_targetLabel`
- `jmfsb_ecoti_fnc_targetVisibility`
- `jmfsb_ecoti_fnc_toggleHideNear`
- `jmfsb_ecoti_fnc_togglePower`
- `jmfsb_ecoti_fnc_updateCandidates`
- `jmfsb_ecoti_fnc_updateVisibility`
- `jmfsb_ecoti_fnc_updateZones`
- `jmfsb_ecoti_fnc_vectorView`
- `jmfsb_ecoti_fnc_vehicleBox`
- `jmfsb_ecoti_fnc_zenMark`

</details>
