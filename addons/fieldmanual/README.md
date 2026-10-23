# Field Manual

`jmfsb_fieldmanual`

The unit's how-to inside Arma's own Field Manual (pause menu > Field Manual),
under a **1st JMSB** category (user, 2026-10-23: "there is a field manual in
arma can we put all our how to data in there"). Config only: no functions,
nothing runs.

**The signs are the source.** The staging-zone boards are the unit's how-to,
and `tools/gen_signs.py` holds their words as data. `tools/gen_fieldmanual.py`
writes the same words into `CfgHints.hpp` - a topic per group, an entry per
board, the board itself (`jmfsb_media` `signs_v2_plain`, the FA boards from
`jmfsb_fa_main`) as the entry's picture - so the manual and the signs cannot
say different things. Change a board in `gen_signs.py`, run both generators.

| Topic | Entries |
|---|---|
| Radio voice | How it works, Your nets, Keys, The phone, The side device, The tablet |
| Staging zone | Arsenal access, Pick role, Operation timeline, Callsigns, Keybinds, Good to knows, View distance, Enemy bodies, Good to know (GTK), Patrol base |
| Map and tablet | Custom info & tacpad, cTab, Marker tree, Markers from range finders |
| Ammunition | The five FA boards |

Left out on purpose: wayfinding boards (a name only), uniform swatches, and
boards that repeat another (`go`, `jmfsbkeys`).

`CfgHints.hpp` is generated - never hand-edit it.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_media`
- `jmfsb_fa_main`
