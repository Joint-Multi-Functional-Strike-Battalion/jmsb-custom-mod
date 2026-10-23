# Mission

`jmfsb_mission`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

**Staging zone satellite uplink** (user, 2026-10-20): every staging zone added with `addStagingZone` (object, marker or position) gets a radio base station at its centre (`stagingUplink` -> `jmfsb_pac_fnc_baseStation`, RF profile `base`) for the players' side; `removeStagingZone` takes it down. Zones are added on the clients, so a client hands the uplink to the server (CBA server event `jmfsb_mission_stagingUplink`), which makes one station per site. It relays the players' nets round the zone and links by satellite to every patrol base and SAT-capable vehicle under open sky. Setting "Staging zone satellite uplink" (default on). See docs/DESIGN_RF.md "Base stations".

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_diag`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

11 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_mission_stagingSatUplink` | CHECKBOX | Staging zone satellite uplink |

## Functions

<details><summary>11</summary>

- `jmfsb_mission_fnc_addBaseCrate`
- `jmfsb_mission_fnc_addEscapeWreck`
- `jmfsb_mission_fnc_addGetOutHelo`
- `jmfsb_mission_fnc_addHaloJump`
- `jmfsb_mission_fnc_addLineJump`
- `jmfsb_mission_fnc_addStagingZone`
- `jmfsb_mission_fnc_doStarterCrate`
- `jmfsb_mission_fnc_makeAgent`
- `jmfsb_mission_fnc_removeStagingZone`
- `jmfsb_mission_fnc_setVehicleLable`
- `jmfsb_mission_fnc_stagingUplink`

</details>
