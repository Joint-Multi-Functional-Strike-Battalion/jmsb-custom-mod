# Artillery Carriers

`jmfsb_artydeploy`

Artillery carriers for the four US factions (desert, OCP, tropic, woodland),
each in its faction's own paint (user, 2026-10-25). Five vehicles - M-ATV
(GMG), M-ATV (HMG), Polaris DAGOR (XM312), Polaris DAGOR (Mini-Spike AT) and
AMV-7 Marshall (APC) - each in two versions ("all vehicles need a version of
either"), 40 classes in all:

| Version | Sets up |
|---|---|
| *vehicle* - Mortar Carrier | the Mk6 mortar |
| *vehicle* - Rocket Artillery | the Western Sahara Hunter-SP launcher, else the Mk6 mortar |

Desert and OCP have no M-ATV GMG / HMG of their own, so theirs are the base
game's sand ones.

**The driver deploys it**, from his ACE self-interaction, ARTILLERY:

1. **Pre-deploy (mark spot)** - an ACE mortar baseplate appears at once 2.5 m
   behind the vehicle's rear edge, where the gun will stand.
2. **Deploy gun** - a progress bar for *Deploy / pack time* (CBA setting,
   60 s), the vehicle stopped and the driver in his seat; then the baseplate
   goes and the gun stands there, facing the way the vehicle faces.
3. **Pack gun** - the same time; AI on the gun is put off it and it goes.
   A player still on the gun stops the pack - he gets off first.
   A gun destroyed or left over 30 m away is simply forgotten.
4. **Clear spot** - takes the baseplate away without deploying.

The server places and removes everything. Each step goes to it by
`remoteExecCall` (`preDeploy`, `deploy`, `undeploy`, `clearSpot`), and the
server checks the driver named is the sending machine's own unit and asks
again whether he may do that step now - driver, vehicle stopped, spot or gun
in the right state (review S6). A server whose CfgRemoteExec is a whitelist
must list those four functions.

A deployed gun crewed by players counts for the enemy's counter-battery
(`jmfsb_reaction`), and the ARTY calculator solves for it when the crew
stands at it.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_faction_us_jtf_des`
- `jmfsb_faction_us_jtf_ocp`
- `jmfsb_faction_us_jtf_tna`
- `jmfsb_faction_us_jtf_wdl`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

40 unit classes, 10 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_artydeploy_time` | SLIDER | Deploy / pack time (s) |

## Functions

<details><summary>10</summary>

- `jmfsb_artydeploy_fnc_addActions`
- `jmfsb_artydeploy_fnc_canAct`
- `jmfsb_artydeploy_fnc_clearSpot`
- `jmfsb_artydeploy_fnc_deploy`
- `jmfsb_artydeploy_fnc_deployStart`
- `jmfsb_artydeploy_fnc_preDeploy`
- `jmfsb_artydeploy_fnc_spot`
- `jmfsb_artydeploy_fnc_undeploy`
- `jmfsb_artydeploy_fnc_undeployStart`
- `jmfsb_artydeploy_fnc_weaponClass`

</details>
