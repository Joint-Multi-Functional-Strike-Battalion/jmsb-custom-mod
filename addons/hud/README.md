# HUD

`jmfsb_hud`

Two readout slots on the game screen, left and right, cycled like the vanilla
info panels. For when you cannot open the map.

## Where they go: Options > Game > Layout

**Not a jmfsb setting, and not a drag handle.** Both slots are registered as IGUI
grids, so they appear in the game's own Layout editor as boxes you can move
**and resize** - a squad list wants to be tall, a jamming bar wants to be short,
and only you know which one you are looking at. The size persists in your profile
like every other element on that screen.

**Out of the box each slot is the base game's own Custom Info panel** - ten grid
cells by ten, at the left and right edges, which is exactly what
`IGUI_GRID_CUSTOMINFO_WDef` / `_HDef` and the two `CUSTOMINFO*_XDef` / `_YDef`
say in the game's `defineCommonGrids.inc`. Nothing inside a slot stretches to
fill it: rows are the suite's own row height and shrink only when a slot is made
too short to hold them, so a box left at its default size reads as a block of
data rather than three lines spread down a panel.

The registry is **`CfgUIGrids >> IGUI`**, in two halves:

```cpp
class CfgUIGrids {
    class IGUI {
        class Presets { class Arma3 { class Variables {
            grid_jmfsb_hudLeft[] = {{"x","y","w","h"}, "cellW", "cellH"};
        };};};
        class Variables {
            class grid_jmfsb_hudLeft {
                displayName = "JMSB HUD - left";
                preview = QPATHTOF(ui\igui_preview.paa);   // required to be listed
                saveToProfile[] = {0, 1, 2, 3};             // move and resize
                canResize = 1;
            };
        };
    };
};
```

**The `preview` is not decoration.** Every working grid in ACE and ACRE carries
one and the editor lists the entry beside it; without it the slot draws on the
Layout screen but never appears in the list to be picked. That was the second
half of this not working, after the wrong config class.

Two earlier attempts wrote grids into `CfgUIColors >> IGUI >> Grids` instead.
That is where the **base game** keeps the positions of its own furniture - which
is why reading it looked correct - but it is not what the Layout editor
enumerates, so the slots showed through on that screen without being editable.
ACE's Micro DAGR uses `CfgUIGrids` and has always been movable; that is the
working example this was rebuilt from.

The profile variables follow the class name **exactly, case included**:
`IGUI_grid_jmfsb_hudLeft_X` / `_Y` / `_W` / `_H`. Not the shouted
`IGUI_GRID_NAME_X` form the base game's own grids use - that was the other half
of why nothing moved.

JMSB's older overlay positioning (`jmfsb_common_fnc_hudPos` and friends, a
bespoke drag-and-save) is superseded by this. It still drives the hacking
scanner strip and the jamming overlay; those move onto grids next.

## The two slots

Each slot cycles through the same ring, and **off is on the ring** - you empty a
slot by pressing past the end, the way the vanilla panels work.

| Tile | Shows |
| --- | --- |
| **DRONES** | Contact count large, then bearing and range. Its own tile because it is the one readout that means *move*. |
| **JAMMING** | Percentage large, a bar under it, and the affected band. |
| **RADIO** | The active voice net (game voice, VON, from `jmfsb_voice_fnc_netState`; never a frequency), `TX` while the player transmits on it, `NO ROUTE` when it is out of reach (never hidden), `MUTED`, or the ear its beeps pan to; under it who is talking on it, or the call - `CALL RINGING`, `CALL <n> ON` - and the jam percentage. Without the voice addon it reads NO VOICE ADDON. |
| **EW** | Drones, jamming and radio on one tile, small. |
| **SQUAD** | `ALL OK` and a headcount, or the casualty list the moment somebody is hit. |
| **TIMER** | World clock, the stopwatch or countdown when one is running, and the next armed alarm. |
| **APS** | The active protection on the vehicle you are in (`jmfsb_aps`): the system's name, charges left and right as bars, the RF emitter ready or counting its cooldown, and the last intercept with its clock bearing. `NO APS` on foot or in a vehicle that carries nothing. |
| *(off)* | Nothing drawn. |

The single tiles are drawn big enough to read while moving. **EW** is the same
three electronic facts at a size you have to stop for - that is the trade a
player makes by choosing it over a slot each.

Both slots offer everything, so a left-hander and a right-hander can each put
what they want where they want it. Defaults are SQUAD left, EW right, and which
slot is showing what persists in your profile.

**SQUAD is quiet until it matters.** A permanent roster of eight names is eight
lines spent telling you what you already know, and by always being there it stops
being read. One line when the section is whole; the list appearing *is* the
alert. Worst first - a list ordered by group index buries the man who is dying
under three men with grazes - and it drops the least urgent rather than growing
past the box you positioned. It reads ACE's unconscious, blood volume and pain
states, falling back to `damage` on a mission not running ACE medical.

## Keys

| Key | Does |
| --- | --- |
| `Shift + [` | Left slot on/off |
| `Shift + ]` | Right slot on/off |
| `Alt + [` | Cycle the left slot |
| `Alt + ]` | Cycle the right slot |

Brackets because the slots are left and right - a mapping nobody has to be told
twice. **Shift gets the simpler job** because it is the one pressed most: turning
a slot off to see the ground under it happens constantly, changing which readout
is in it happens once a patrol.

The on/off keys **remember**. Off is on the cycle ring too, so you *can* reach it
by stepping past the end - but then getting back to the squad list means stepping
through the rest. Toggling puts back whatever the slot was showing.

Note `jmfsb_dtvd` already uses `Ctrl + [` and `Ctrl + ]` for view distance;
these are deliberately on different modifiers. All four are rebindable under
**1st Joint Multi-Functional Strike Battalion**.

## It measures nothing

Every number belongs to the addon that owns it: `jmfsb_hacking_fnc_scannerRead`
for the sweep, `jmfsb_tacpad_apps_fnc_timerState` for the stopwatch,
`jmfsb_hacking`'s roster for the alarms. The HUD and the map screens read the
same sources, so they cannot disagree - and it draws with the tacpad's own
`drawFill`/`drawFrame`/`drawText`, so there is one design in this mod rather than
one design and something that resembles it.

## With the map open

The HUD hides by default - the tacpad says all of this in more detail on the map
screen, and two copies of the squad list on one screen is one too many. The
controls are hidden rather than the layer torn down; cutting a title layer twice
a minute is how a HUD starts flickering. Switchable off in settings.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_tacpad`
- `cba_xeh` _(external)_

## Ships

16 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_hud_enabled` | CHECKBOX | Enable HUD |
| `jmfsb_hud_hideOnMap` | CHECKBOX | Hide with the map |
| `jmfsb_hud_showInTablet` | CHECKBOX | Show in tablet mode |
| `jmfsb_hud_opacity` | SLIDER | HUD opacity |

## Functions

<details><summary>16</summary>

- `jmfsb_hud_fnc_close`
- `jmfsb_hud_fnc_cycle`
- `jmfsb_hud_fnc_draw`
- `jmfsb_hud_fnc_hidden`
- `jmfsb_hud_fnc_open`
- `jmfsb_hud_fnc_setShown`
- `jmfsb_hud_fnc_slotState`
- `jmfsb_hud_fnc_sweep`
- `jmfsb_hud_fnc_toggle`
- `jmfsb_hud_fnc_widgetAps`
- `jmfsb_hud_fnc_widgetDrones`
- `jmfsb_hud_fnc_widgetEw`
- `jmfsb_hud_fnc_widgetJamming`
- `jmfsb_hud_fnc_widgetRadio`
- `jmfsb_hud_fnc_widgetSquad`
- `jmfsb_hud_fnc_widgetTimer`

</details>
