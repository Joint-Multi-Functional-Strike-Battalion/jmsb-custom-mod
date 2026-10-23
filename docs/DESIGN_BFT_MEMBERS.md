# BFT member icons - design

Addon: `addons/bft`. Changes `fnc_drawMembers.sqf` only, plus 3 textures.
Status: design, for code. Date 2026-10-19.

## Goal

Every member mark on the map shows three things at a glance:

1. **Who** - his member number, from `ghostD_bft_fnc_memberNumber` (already in the addon).
2. **Team** - fill colour = his ACE3 fire team (`assignedTeam`).
3. **Facing** - a pointer on the circle that turns with his heading.

Plus a ring when he is talking.

Same icon on the map, the tablet, the phone and the side devices. One draw function, no copies.

## Reference

What it should look like (from the user):

![reference](../art/images/bft_member_reference.png)

Built from the textures below, all five teams, three voice states:

![preview](../art/images/bft_member_preview.png)

## The icon

Layers, bottom to top, all drawn at the unit's `getPosATLVisual`:

| Layer | Texture | Colour | Rotates |
|---|---|---|---|
| Voice ring (only when talking) | `member_ring_ca.paa` | red = radio TX, magenta = direct voice | no |
| Outline | `member_outline_ca.paa` | dark `[0.13,0.12,0.11,1]` | yes, `getDirVisual` |
| Body (circle + pointer) | `member_body_ca.paa` | team colour | yes, `getDirVisual` |
| Number | text only | white; dark on MAIN and YELLOW | no |

- The number moves into the circle. The label beside the icon goes back to the name only (today it reads `"<N> <name>"`).
- Number must never rotate. Draw it as its own `drawIcon` call with a transparent texture (`#(argb,8,8,3)color(0,0,0,0)`) and centred text. Check that `"center"` text align really centres on the position; if it offsets, adjust with a small map-space shift.
- Pointer is part of the body texture, pointing up (north) at 0. `drawIcon` angle = `getDirVisual _unit`.
- Size: keep `MEMBER_SIZE` 24 as the body size. Ring is drawn at the same size (it is in the same 128 px canvas, outer ring at the edge).

## Colours (ACE3 / vanilla team colours)

| Team | Fill RGBA | Number text |
|---|---|---|
| MAIN | `[1,1,1,1]` | dark |
| RED | `[0.90,0.22,0.21,1]` | white |
| GREEN | `[0.26,0.63,0.28,1]` | white |
| BLUE | `[0.12,0.53,0.90,1]` | white |
| YELLOW | `[0.99,0.85,0.21,1]` | dark |

Unknown team falls back to MAIN.

## Voice rings

- **Red** = he is transmitting on a radio net.
- **Magenta** = he is speaking in direct (local) voice.
- None = silent.
- Radio wins if both are true.
- Source: the voice adapter's `talking` list (VON: `getPlayerChannel`; TFAR adapter: its speaking events). Read it in the existing slow pass (`FUNC(draw)`) into a hashmap `unit -> 0/1/2`, so the per-frame draw only looks it up.
- **Confirm with user:** which ring colour means radio and which means direct. This doc assumes red = radio, magenta = direct.

## States worth showing (keep it small)

- Dead units: not drawn (as now).
- Unconscious (ACE): body alpha 0.5. Optional, setting.
- No change for wounded here; that belongs to the phone's squad list.

## Textures

PNG sources are in `images/`, white on transparent, 128 x 128. Convert with ImageToPAA and place in `addons/bft/data/`:

- `member_body_ca.png` - circle centred, pointer on top.
- `member_outline_ca.png` - same shape a little larger, for the dark edge.
- `member_ring_ca.png` - two dashed rings.

Paths in code: `QPATHTOF(data\member_body_ca.paa)` etc.

## Code changes

`fnc_drawMembers.sqf`:

1. Replace `MEMBER_ICON` (vanilla iconman) with the three textures.
2. Per unit, in this order: ring (if talking), outline, body, number text.
3. Name label stays: drawn with the body, `"left"` align, text = `name _x` only.
4. Colours table as above.
5. Number from `[_x] call FUNC(memberNumber)`.

`fnc_draw.sqf`:

- Build `GVAR(memberVoice)` (hashmap unit -> 0 none / 1 direct / 2 radio) in the same pass that builds `GVAR(memberUnits)`. No voice adapter = all 0.

Per-frame cost: up to 4 `drawIcon` calls per member, own squad by default. Fine.

## Settings

- Existing `memberMarkers` (Off / Own squad / All tracked) unchanged.
- New `memberVoiceRings` CHECKBOX, default on.

## Not in scope

- Group (NATO) markers for other groups: unchanged.
- Phone/side device layouts: separate doc ([SPEC_DEVICES.json](SPEC_DEVICES.json)).
