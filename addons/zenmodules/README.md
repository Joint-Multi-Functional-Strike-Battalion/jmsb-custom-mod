# Zenmodules

`jmfsb_zenmodules`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

**Call Endex** (`fnc_callEndex`): the Zeus's machine asks the server by
`remoteExecCall` to `jmfsb_zenmodules_fnc_endexRequest`, to call it or call
it off. The server serves it only to a sender who holds a curator module or
is an admin by its own records. It then sets the Endex flag, shows the
notices and the hint, and on a call sends the local share (weapons safe, AI
careless, hold-fire warnings, heal) to every machine by `remoteExecCall` to
`jmfsb_zenmodules_fnc_endexLocal`, which takes it only from the server
(review S7: it was a CBA global event any client could raise). The flag
(`jmfsb_Mission_Endex`) is the server's: kept in its `localNamespace`, with a
public copy for the hold-fire handlers that the server publishes again if a
client overwrites it. A server whose CfgRemoteExec is a whitelist must list
both functions.

A player who fires during endex sends the shot to the server by
`remoteExecCall` to `jmfsb_zenmodules_fnc_srvEndexFired`, which logs it and
tells everyone "Hold your fire" once per muzzle - only while the server's own
flag is up, and naming the sender, never a name the call carries (review R1:
the client used to post it to every screen itself).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_diag`
- `jmfsb_notify`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

15 functions.

## Functions

<details><summary>15</summary>

- `jmfsb_zenmodules_fnc_addStaging`
- `jmfsb_zenmodules_fnc_callEndex`
- `jmfsb_zenmodules_fnc_createFieldHospital`
- `jmfsb_zenmodules_fnc_createMedicalCrate`
- `jmfsb_zenmodules_fnc_createStaging`
- `jmfsb_zenmodules_fnc_createStarterCrate`
- `jmfsb_zenmodules_fnc_createSupplyCrate`
- `jmfsb_zenmodules_fnc_enableUnitSimulation`
- `jmfsb_zenmodules_fnc_endexFired`
- `jmfsb_zenmodules_fnc_endexLocal`
- `jmfsb_zenmodules_fnc_endexRequest`
- `jmfsb_zenmodules_fnc_rekitVehicle`
- `jmfsb_zenmodules_fnc_setDamage`
- `jmfsb_zenmodules_fnc_srvEndexFired`
- `jmfsb_zenmodules_fnc_stagingZones`

</details>
