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

**The server checks who asks (review S7).** Requests go to the server by
`remoteExec`, never a CBA event:

- **Build** (`jmfsb_patrol_base_fnc_serverBuild`): only the name travels. The
  builder is the sending machine's player; position, direction and side are
  his, read on the server, which re-checks alive, on foot, kits in range and
  the base limit. The on-deploy hook runs a frame later as the server's own
  code.
- **Unbuild** (`jmfsb_patrol_base_fnc_serverUnbuild`): taken only from a
  living player within 10 m of the beacon.
- **Zeus kit drop** (`jmfsb_patrol_base_fnc_dropKits`): taken only from an
  admin by the server's records or a player holding a curator module; the
  kit count is the server's "Kits required" setting.

A mission that whitelists `CfgRemoteExec` must list these three.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

2 unit classes, 2 weapon/item classes, 13 functions.

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

<details><summary>13</summary>

- `jmfsb_patrol_base_fnc_addUnbuildAction`
- `jmfsb_patrol_base_fnc_addZeusModule`
- `jmfsb_patrol_base_fnc_canPickupKit`
- `jmfsb_patrol_base_fnc_countKits`
- `jmfsb_patrol_base_fnc_dropKits`
- `jmfsb_patrol_base_fnc_establishPatrolBase`
- `jmfsb_patrol_base_fnc_initPlayer`
- `jmfsb_patrol_base_fnc_kitPickup`
- `jmfsb_patrol_base_fnc_promptName`
- `jmfsb_patrol_base_fnc_runHook`
- `jmfsb_patrol_base_fnc_serverBuild`
- `jmfsb_patrol_base_fnc_serverUnbuild`
- `jmfsb_patrol_base_fnc_spawnKits`

</details>
