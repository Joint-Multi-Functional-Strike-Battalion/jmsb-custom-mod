# Drone40

`jmfsb_drone40`

Three more rounds for the GX Drones mod's Drone40 (the RC 40): a relay, a decoy
and a jammer. Loads only with GX (`skipWhenMissingDependencies` on
`gx_drones_uav_drone40`). NOT RUN IN GAME.

## The rounds

Each is GX's recon round with its own shell and drone, so it loads, fires,
unfolds, is placed, hand-deployed, recharged and picked up exactly like GX's
own, and the operator keeps the recon camera and laser designator. Picture,
model and textures are GX's recon ones.

| Round (magazine) | Shell (ammo) | Drone (B / O / I) |
|---|---|---|
| `jmfsb_drone40_1Rnd_relay_M203` | `jmfsb_drone40_relay_shell` | `jmfsb_drone40_B_relay` / `_O_relay` / `_I_relay` |
| `jmfsb_drone40_1Rnd_decoy_M203` | `jmfsb_drone40_decoy_shell` | `jmfsb_drone40_B_decoy` / `_O_decoy` / `_I_decoy` |
| `jmfsb_drone40_1Rnd_jammer_M203` | `jmfsb_drone40_jammer_shell` | `jmfsb_drone40_B_jammer` / `_O_jammer` / `_I_jammer` |

They go where GX's rounds go: the `CBA_40mm_M203` and `UGL_40x36` magazine
wells, and the vanilla `UGL_F` magazine list. A round laid on the ground has an
"Assemble Drone40 (...)" action, as GX's have.

## What each does

The machine that made the drone (the launcher's) tells the server who launched
it; the server does the rest. Every `TICK_S` (5 s) it drops a drone that died
or was picked up, and mirrors its battery: a flat drone is "off" in RF.

- **Relay.** An RF node, profile `droneRelay` (VHF/UHF, 2 W, -112 dBm, 3 dBi,
  4 hops, relay, 20 dB spread, battery of its host). It holds the launcher's
  own fill - every net and key his radios hold (`jmfsb_rf_fnc_nodesFor`) - so it
  relays his side's mesh.
  Its position is the drone's, so altitude clears terrain. Holder: the
  launcher. No launcher, or one with no radio node: RF's DATA net only.
- **Jammer.** While it is alive and has battery it is an RF noise source
  (`jmfsb_rf_fnc_addNoiseSource`), and nothing else: VHF and UHF links near it
  lose SNR, barrage-style, so spread gain helps. Its noise is the power setting
  plus a 3 dBi whip, less the band's clear-ground path loss
  (`jmfsb_rf_fnc_pathLossFree`), out to the radius setting. It jams its own
  side too. Voice feels it through RF link quality (`jmfsb_voice`). It
  lays no `jmfsb_jamming` zone any more, so the jam meter, TAC//MSG link state
  and the scanner (all `jmfsb_jamming_fnc_jamFactor`) do not see it. It is not
  an RF node (RF has no jammer profile); with `jmfsb_ew` loaded it is an EW
  emitter (`jmfsb_ew_fnc_addEmitter`, intent `jam`), so ES hears, DFs and
  classes it as a JAMMER, and a flat one is dark.
- **Decoy.** An RF node with the handheld profile, so it emits on a handheld's
  bands at a handheld's power. It claims the launcher's nets under a key nobody
  else holds, so it carries no traffic and links with nobody; relay is off and
  its node carries `intent = "decoy"` in its data field (`jmfsb_rf_fnc_register`
  arg 7). `jmfsb_ew` hears it as a handheld: enemy ES DFs and tracks it, and
  classes it DECOY? only after two minutes without traffic. EW's own placed
  decoys use the same mark.

## Modes

`jmfsb_drone40_fnc_setMode [drone, mode]` switches any of the three between
`relay`, `decoy`, `jammer` and `off`, whatever round it came from. It is the
server's: called anywhere else it raises `jmfsb_drone40_setMode` to the server.
There the drone's node goes (`fnc_remove`: its RF node, or the jammer's EW
emitter through `jmfsb_ew_fnc_removeEmitter`), the mode is set public on the
drone (`jmfsb_drone40_mode`; a fresh drone carries its round's role), and
unless it is `off` the drone is registered again exactly as at launch
(`fnc_deploy`), with the launcher kept on the drone. Off: no node, no noise, no
emitter. The tablet's DRONES app shows the mode and the switches for a Drone40
the player holds or may link. `fnc_deploy` also records where the launcher stood
as the drone's home for RTB (`jmfsb_devices_uavHome`). NOT RUN IN GAME.

## Settings

Radius and power of the jammer, under 1st Joint Multi-Functional Strike
Battalion > Drone40. Power is the barrage's dBm in the RF budget; radius is how
far it counts at all.

## EW (docs/DESIGN_EW.md)

`jmfsb_ew` DFs the relay and the decoy as RF nodes and the jammer as an
external emitter. The jammer stays a barrage on VHF/UHF: spot and sweep are
the EW Jammer Pack's.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_rf`
- `cba_xeh` _(external)_
- `gx_drones_uav_drone40` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

9 unit classes, 7 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_drone40_jammerRadius` | SLIDER | Jammer radius (m) |
| `jmfsb_drone40_jammerPower` | SLIDER | Jammer power (dBm) |

## Functions

<details><summary>7</summary>

- `jmfsb_drone40_fnc_deploy`
- `jmfsb_drone40_fnc_init`
- `jmfsb_drone40_fnc_launcherNets`
- `jmfsb_drone40_fnc_noise`
- `jmfsb_drone40_fnc_remove`
- `jmfsb_drone40_fnc_setMode`
- `jmfsb_drone40_fnc_tick`

</details>
