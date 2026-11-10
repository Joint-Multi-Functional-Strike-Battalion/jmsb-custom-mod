# Range

`jmfsb_range`

Shooting ranges on pop-up targets. Our own code; the method follows Jonpas's
shooting range (Theseus / 61st lxim, GPL), which is reference only - nothing
copied.

**JMSB - Shooting Range** module, one per range:

- Sync the range's pop-up targets and a controller object (laptop, sign,
  table) to it, or name them in the module.
- The controller gets an ACE menu: the range, its mode and settings, Start,
  Stop.
- Modes:
  - Pop-ups, timed: one target up at a time, for the duration.
  - Pop-ups, set number: one at a time, a set number of targets.
  - Rampage: all up, clear them; the duration is the limit.
- A target goes down when hit; the next comes up at once, or when its
  exposure time is up.
- Only the shooter who pressed Start scores. Anyone else firing is told the
  range is in use.
- Stop: the shooter, an admin, or anyone once the shooter is gone. A stopped
  run keeps no score.

Results go to the shooter and everyone within 50 m.

**Save score to PAC** (module, on by default): each finished run goes on the
shooter's PAC record, `ranges` -
`[date, range, mode, detail, hits, shown, seconds]`, the last 20 per range.
Shown on the TAC//PAC player page (RANGES tab) and the website's player page,
the latest run of each range highlighted. Use the same range name in every
mission so scores line up.

Off a running range the targets behave as the game's own: down when hit, up
again after 3 s, unless the mission sets `nopop`.

**Target groups** - an instructor's board, no score. In the controller's init
field:

    [this, [["Left 1", ["mg_t1", "mg_t2"]], ["Far", ["mg_t9"]]]] call jmfsb_range_fnc_targetGroups

- ACE: Targets > All up, All down, and one entry per group that raises it.
- Targets start down, and a hit target stays down until raised again.
- Targets are objects or their names.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `A3_Data_F_Decade_Loadorder` _(external)_

## Ships

1 unit class, 14 functions.

## Eden modules

### JMSB - Shooting Range

`jmfsb_range_module`

Shown in the menu, the results and the PAC record. Keep it the same between missions so scores line up.

## Functions

<details><summary>14</summary>

- `jmfsb_range_fnc_aceActions`
- `jmfsb_range_fnc_detail`
- `jmfsb_range_fnc_finish`
- `jmfsb_range_fnc_handleHit`
- `jmfsb_range_fnc_isDown`
- `jmfsb_range_fnc_moduleInit`
- `jmfsb_range_fnc_resolve`
- `jmfsb_range_fnc_session`
- `jmfsb_range_fnc_setTarget`
- `jmfsb_range_fnc_setting`
- `jmfsb_range_fnc_start`
- `jmfsb_range_fnc_stop`
- `jmfsb_range_fnc_targetGroups`
- `jmfsb_range_fnc_tell`

</details>
