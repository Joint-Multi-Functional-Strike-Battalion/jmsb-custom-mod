# Side devices - design

Devices: side and side2 (arsenal GPS slot, player carries one). Spec: [SPEC_DEVICES.json](SPEC_DEVICES.json).
Status: design, for code. Date 2026-10-19.
Related: [DESIGN_PHONE_WALKING.md](DESIGN_PHONE_WALKING.md) (same content, landscape), [DESIGN_BFT_MEMBERS.md](DESIGN_BFT_MEMBERS.md).

## What it is

Same job as the phone walking view, upright. Side and side2 are two different bodies with ONE shared screen. Each device scales the same screen into its own glass.

## Images

In game, 1080p (both shown; a player has one):

![in game](../art/images/side_ingame.png)

Side (keys on the side) and side2 (keys on the bottom):

![side](../art/images/side_device.png) ![side2](../art/images/side2_device.png)

Shared screen (2x design units):

![screen](../art/images/side_screen.png)

Canvas: TAC//APP Side Devices (artifact NaUeVyz9NDuCpGo9QrEpNP).

## Size and placement

Frame height 480 px at 1080p, 24 px from the screen edge.

| | Side | Side2 |
|---|---|---|
| Default place | lower left | lower right |
| Frame (1080p) | 282 x 480 | 429 x 480 |
| Screen (1080p) | 156 x 259 | 211 x 354 |
| Texture | `mini_body_cut.png` 1203 x 2048 | `mini2_body_cut.png` 1831 x 2048 |
| Glass rect in texture | 286,485 - 952,1591 | 456,285 - 1358,1797 |
| Screen scale from 2x | 0.26 | 0.35 |

- Shared screen design: 600 x 1000 (2x units, ratio 0.6). Both glasses are ~0.6, so it fits with no crop; centre it.
- CBA setting: left / right per device. Size setting (frame height) 360 - 600, default 480. Side at 480 is small: text is ~5 px. Recommend 600 for side, or larger fonts on side only.

## Layout (top to bottom, 2x units)

| Row | Height | Content |
|---|---|---|
| Map | rest | centred on player; grid readout bottom right, call strip bottom left |
| Squad list | ~90 | 2 columns x 3 rows |
| Nets | ~132 | 2 columns x 3 rows, cells 36 high |

Everything else (sources, colours, flags, icons, behaviour) is the phone's. See [DESIGN_PHONE_WALKING.md](DESIGN_PHONE_WALKING.md).

Differences from the phone:

- No status icons and no notification line (removed 2026-10-21, as on the phone).
- Map is taller than wide, so it shows more ground ahead and behind. Same 50 m radius across the width.
- Squad list moves below the map, 2 columns. Same `<N> <NAME>` and flags.
- Who is talking chip: top left of the map.
- Nets in a 2-column grid, only nets you are on. Numpad 0 / . move the active net.

## Keys on the body

F1-F4 and left/right arrows are printed on both bodies. Ctrl + numpad 1-4 are F1-F4, plain numpad 1-4 select nets 1-4, and numpad 0 / . are the arrows (see DESIGN_VOICE.md). Walking view: F1 accept call, F2 ear / quick add, F3 mute, F4 decline / hang up. Numpad 6 opens the RADIO app full screen. Old mapping was (F1 2nd PTT, F2 ear, F3 vol, F4 close) when the fullscreen pages exist.

## Build notes

- One display class for the screen content, two frame classes. The screen group is placed and scaled per device from the table above.
- Same `RscTitles` / `cutRsc` approach and map-control checks as the phone.
- Member icons: hook `ghostD_bft_fnc_drawMembers` on this map control too.

## Not in scope

- Fullscreen pages, settings, apps.
- A different screen per device: both share one screen.
