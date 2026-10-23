# Patrol Base

`jmfsb_patrol_base`

A buildable patrol base anyone can deploy - kit items and props,
a Zeus drop, a name popup and a map marker.

**Radio relay** (user, 2026-10-20): a built base carries a radio base station
on its mast (`jmfsb_pac_fnc_baseStation`, RF profile `base`), for the
builder's side. It relays the side's nets round the base and links by
satellite, in one hop at any distance, to the staging zone and every other
base while the mast has open sky. Unbuilding the base, or the mast being
destroyed or deleted, takes it down. Setting "Patrol base radio relay"
(default on). See docs/DESIGN_RF.md "Base stations".

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_notify`

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

2 unit classes, 2 weapon/item classes, 12 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_patrol_base_enabled` | CHECKBOX | Enabled |
| `jmfsb_patrol_base_radioRelay` | CHECKBOX | Patrol base radio relay |
| `jmfsb_patrol_base_maxCount` | SLIDER | Max patrol bases |
| `jmfsb_patrol_base_kitCount` | SLIDER | Kits required |
| `jmfsb_patrol_base_kitRange` | SLIDER | Kit gather range (m) |
| `jmfsb_patrol_base_beaconClass` | EDITBOX | Base object |
| `jmfsb_patrol_base_onDeployCode` | EDITBOX | On-deploy init (SQF) |
| `jmfsb_patrol_base_onUndeployCode` | EDITBOX | On-undeploy init (SQF) |

## Functions

<details><summary>12</summary>

- `jmfsb_patrol_base_fnc_addUnbuildAction`
- `jmfsb_patrol_base_fnc_addZeusModule`
- `jmfsb_patrol_base_fnc_canPickupKit`
- `jmfsb_patrol_base_fnc_countKits`
- `jmfsb_patrol_base_fnc_establishPatrolBase`
- `jmfsb_patrol_base_fnc_initPlayer`
- `jmfsb_patrol_base_fnc_kitPickup`
- `jmfsb_patrol_base_fnc_promptName`
- `jmfsb_patrol_base_fnc_runHook`
- `jmfsb_patrol_base_fnc_serverBuild`
- `jmfsb_patrol_base_fnc_serverUnbuild`
- `jmfsb_patrol_base_fnc_spawnKits`

</details>
