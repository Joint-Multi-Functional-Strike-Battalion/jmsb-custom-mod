# Players

`jmfsb_players`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_diag`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

12 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_players_enableClanTag` | CHECKBOX | Use squad tags in names |

## Functions

<details><summary>12</summary>

- `jmfsb_players_fnc_exportRanks`
- `jmfsb_players_fnc_getClanTag`
- `jmfsb_players_fnc_getRank`
- `jmfsb_players_fnc_hasClanTag`
- `jmfsb_players_fnc_isCurator`
- `jmfsb_players_fnc_platoonNet`
- `jmfsb_players_fnc_platoonOf`
- `jmfsb_players_fnc_setRank`
- `jmfsb_players_fnc_setRankOverride`
- `jmfsb_players_fnc_unit_getName`
- `jmfsb_players_fnc_unit_getSquadName`
- `jmfsb_players_fnc_unit_getVariables`

</details>
