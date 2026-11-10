# C2

`jmfsb_c2`

C2 measures (`docs/DESIGN_WATCH_HUD.json`, c2_app, decided 2026-11-07). Team leads and ATLs (the role's isLeader) draw them; the whole side sees them.

| Lines | Areas | Points |
|---|---|---|
| phase line, LOA (red), boundary, route | objective, no fire area (red) | LZ, rally point, checkpoint |

## Making one - TAC//C2 on the tablet

1. Pick the type.
2. Draw it with the map TOOLS > ROUTE: press the points (a line two or more, an area three or more, a point one - the last pressed).
3. Type the name.
4. SAVE.

The list shows the side's measures, who drew them and how far. DELETE: the creator, a team lead or an ATL. The C2 tile is for leaders; it shows the count and the last reportable event.

## Seeing them

- **Map:** every measure on every map - main map, tablet, BFT - lines as lines, areas closed, points as icons, each with its name.
- **World** (AiTR goggles): lines and areas on the ground within 1 km, name and distance at the nearest point. Points: a dot beyond 250 m, icon, name and distance within.

## What they do

| Measure | When | |
|---|---|---|
| Phase line | you cross it | CROSSED PL BLUE - reportable |
| Boundary | you cross it | warning |
| LOA | within 50 m | DO NOT CROSS warning; crossed: PAST LOA - GO BACK, reportable |
| Objective | you step inside | ON OBJ RED - reportable |
| Rally point | within 25 m | AT RP 1 - reportable |
| Checkpoint | within 25 m | PASSED CP 3 - reportable |
| No fire area | a fires or CAS request from inside it | refused (CANTCO) by the support system |

**Reporting:** within a minute of a reportable event, the action key (numpad 9) with nothing looked at sends it to C2.reports as one line with your group and grid.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `cba_settings` _(external)_

## Ships

14 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_c2_hud` | CHECKBOX | HUD: C2 measures |

## Functions

<details><summary>14</summary>

- `jmfsb_c2_fnc_app`
- `jmfsb_c2_fnc_canEdit`
- `jmfsb_c2_fnc_delete`
- `jmfsb_c2_fnc_draw`
- `jmfsb_c2_fnc_inNoFire`
- `jmfsb_c2_fnc_intersects`
- `jmfsb_c2_fnc_markers`
- `jmfsb_c2_fnc_nearest`
- `jmfsb_c2_fnc_publish`
- `jmfsb_c2_fnc_report`
- `jmfsb_c2_fnc_save`
- `jmfsb_c2_fnc_tick`
- `jmfsb_c2_fnc_tile`
- `jmfsb_c2_fnc_typeOf`

</details>
