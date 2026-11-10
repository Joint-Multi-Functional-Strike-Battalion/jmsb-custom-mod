# Field Manual

`jmfsb_fieldmanual`

The unit's how-to inside Arma's own Field Manual (pause menu > Field Manual),
as **1st JMSB - ...** topics (user, 2026-10-23: "there is a field manual in
arma can we put all our how to data in there"). Config only: no functions,
nothing runs.

**The signs are the source.** The staging-zone boards are the unit's how-to,
and `tools/gen_signs.py` holds their words as data. `tools/gen_fieldmanual.py`
writes the same words into `CfgHints.hpp` - a topic per group, a page per
board, the board itself (`jmfsb_media` `signs_v2_plain`, the FA boards from
`jmfsb_fa_main`) as the entry's picture - so the manual and the signs cannot
say different things. Change a board in `gen_signs.py`, run both generators.

| Topic | Pages |
|---|---|
| 1st JMSB - Radio voice | Numpad - Device Keys, Numpad - Tablet, How it works, Your nets, Keys |
| 1st JMSB - Radios | The radios |
| 1st JMSB - Devices | The phone, the side device, and their simple versions |
| 1st JMSB - Tablets | The tablet, its apps, the simple tablet |
| 1st JMSB - Staging zone | Arsenal access, Pick role, Operation timeline, Callsigns, Keybinds, Good to knows, View distance, Enemy bodies, Good to know (GTK), Patrol base |
| 1st JMSB - Map and tablet | Custom info & tacpad, cTab, Marker tree, Markers from range finders |
| 1st JMSB - Ammunition | The five FA boards |

**Two levels only.** The game reads CfgHints as topic, then page. A category
over the topics left every page empty in game (user, 2026-10-25), so each
topic is its own root class.

Left out on purpose: wayfinding boards (a name only), uniform swatches, and
boards that repeat another (`go`, `jmfsbkeys`).

`CfgHints.hpp` is generated - never hand-edit it.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_media`
- `jmfsb_fa_main`
