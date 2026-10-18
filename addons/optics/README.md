# Optics

`jmfsb_optics`

Scopes, including ACE XM157 fire-control grafted onto remote sights.

**The goggles see through every scope** (user, 2026-10-17). A scope mode that
names its own vision modes switches night vision off when you look through it -
and one that lists NVG still opens in Normal. So every scope mode without
thermal names none (`visionMode[] = {}`), the way a red dot does: NVG on, NVG in
the scope; off, a normal scope. Thermal scopes keep their modes, with NVG added.
CBA's picture-in-picture scopes (the Vortex M157) are put in the goggle's mode
by `jmfsb_nvg_fnc_syncPipVision`. The configs live in
`compatibility/nvg_optics_<mod>`, one sub-addon per mod, generated:

1. `python tools/optics_from_pbos.py` - reads the base game and every mod in
   the JMSB launcher preset (`jmsb_b1_edit`) off disk into
   `tools/_dump/optics.txt`. (Or, in game: paste `tools/dump_optics.sqf` into
   the debug console and paste the clipboard into that file - the COMPLETE
   route: creator DLC is encrypted on disk, and some mods ship obfuscated PBOs
   - SPS Equipment's Vortex Spitfire - that only the game should read.)
2. `python tools/gen_nvg_optics.py`, then `python tools/check_all.py`.

Re-run it when the arsenal gains a scope from a new mod.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `A3_Weapons_F` _(external)_
- `A3_Weapons_F_Mark` _(external)_
- `ace_xm157` _(external)_
- `cba_jr` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

7 unit classes, 9 weapon/item classes.
