# Acre_faces

`jmfsb_acre_faces`

The channel card, on the radio. ACRE draws each handset as a stack of pictures
over a body plate; this replaces the plate on the PRC-148 and the PRC-152 with
one that has the net plan written on it - paint pen on the 148's battery, a
taped card on the 152's - and a worn unit mark beside it. Every knob, key and
readout is still ACRE's own.

The 148 carries the fourteen team nets, one channel per element, in
`group_setup` order. The 152 carries the sixteen named nets with their
frequencies, because the man reading it is about to turn to one of them.

**The lists are tables at the top of `tools/gen_radio_faces.py`** - change a
line, re-run, done. Nothing checks that the picture agrees with the mission's
`config\config_radio.hpp`, because a painted card cannot read a config: change
the plan and the card in the same commit.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `acre_sys_prc148` _(external)_
- `acre_sys_prc152` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.
