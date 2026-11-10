# Systems

`jmfsb_systems`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

Heal All goes to the server by `remoteExec` (`srvHealAll`), which heals and
tells the players round the object only for a living caller at it; the
server metrics answer only an admin, on his own machine (review R1: both
used the notify post CBA event, which any client could aim at anyone).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_diag`
- `jmfsb_notify`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

22 functions.

## Functions

<details><summary>22</summary>

- `jmfsb_systems_fnc_addHeal`
- `jmfsb_systems_fnc_addHealall`
- `jmfsb_systems_fnc_addObjectToCurator`
- `jmfsb_systems_fnc_checkStagingZone`
- `jmfsb_systems_fnc_createActionCategory`
- `jmfsb_systems_fnc_createVehicleLable`
- `jmfsb_systems_fnc_deleteDroppedObjects`
- `jmfsb_systems_fnc_doGetOutHeloSide`
- `jmfsb_systems_fnc_dynamicMarkers`
- `jmfsb_systems_fnc_getAttendance`
- `jmfsb_systems_fnc_getIcon`
- `jmfsb_systems_fnc_getServerMetrics`
- `jmfsb_systems_fnc_getVehicleLable`
- `jmfsb_systems_fnc_isInStagingZone`
- `jmfsb_systems_fnc_isValidFaction`
- `jmfsb_systems_fnc_para_backpack`
- `jmfsb_systems_fnc_para_equipment`
- `jmfsb_systems_fnc_para_haloJump`
- `jmfsb_systems_fnc_para_lineJump`
- `jmfsb_systems_fnc_renameObject`
- `jmfsb_systems_fnc_setUnitInjury`
- `jmfsb_systems_fnc_srvHealAll`

</details>
