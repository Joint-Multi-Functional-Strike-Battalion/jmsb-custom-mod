# Logistics

`jmfsb_logistics`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

A supply crate (`doSupplyCrate`) can be dragged and carried by everyone,
players who join later too: ACE's setters are local, so the server sends
`crateDraggable` to every machine by `remoteExecCall`, JIP-tied to the crate so
it goes when the crate does (review L3). The receiver takes it only from the
server, and a client's `doSupplyCrate` (the Zeus crate modules) passes only
for a curator or an admin (review R1). It was a CBA event, which any client
could raise to make any object draggable.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_diag`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

12 functions.

## Functions

<details><summary>12</summary>

- `jmfsb_logistics_fnc_addCargo`
- `jmfsb_logistics_fnc_checkItemValidity`
- `jmfsb_logistics_fnc_crateDraggable`
- `jmfsb_logistics_fnc_createCargoCrate`
- `jmfsb_logistics_fnc_doEmptyCrate`
- `jmfsb_logistics_fnc_doFieldHospital`
- `jmfsb_logistics_fnc_doStarterCrateSupplies`
- `jmfsb_logistics_fnc_doSupplyCrate`
- `jmfsb_logistics_fnc_getAllContainerItems`
- `jmfsb_logistics_fnc_getContainer`
- `jmfsb_logistics_fnc_setCargo`
- `jmfsb_logistics_fnc_setCargoAttributes`

</details>
