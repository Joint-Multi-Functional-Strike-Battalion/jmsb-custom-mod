# Hacking

`jmfsb_hacking`

The intel economy. Towers and enemy handsets are things you can
break into, and what you get out is one product of your choosing.

Every product is a SNAPSHOT drawn by one renderer - a circle that was true when
it was earned, never a live feed - so products can differ in what they know and
never in how they look. That matters more than it sounds: it is what makes a
poisoned product indistinguishable from an honest one, by design.

The tightening ladder is the other half. Repeat hacks on one target step the
circle down a size, and the throw is cached per tier so repetition CONFIRMS
without ever narrowing - which closes the intersect-three-circles exploit while
leaving cross-tier overlap working as intended.

**SPOOF** (2026-10-20). A unit's net - an enemy handset, or a crewed vehicle
the operator's set hears carrying an RF set (`jmfsb_hacking_rfReach`, the HACK
board's RF answer) - can be broken into for a GPS spoof instead of a product:
the HACK app's ACTIONS row picks TAP or SPOOF (`fnc_canSpoof`,
`fnc_tabletSelectAction`, kept in the session as `action`). The hack itself is
unchanged - same reach, clock, ISR and condition gates, fail roll and net
detection roll; only completion differs: `fnc_hackComplete` hands the net's
group to `jmfsb_ew_fnc_spoofNode`, whose spoof engine walks every man's GPS
off true for its own setting's length. Their BFT dots and their DF cuts follow
the false fix, so the fixes their side makes land off target. No `jmfsb_ew`:
SPOOF is not offered.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `ace_interact_menu` _(external)_
- `ace_common` _(external)_
- `jmfsb_notify`
- `jmfsb_common`
- `cba_xeh` _(external)_

## Ships

2 unit classes, 4 weapon/item classes, 61 functions.

## Eden modules

### JMSB - Intel Package

`jmfsb_moduleIntelPackage`, category jmfsb_modules

Puts an intel package on a device. Hacking that device hands over a share of it.<br>Package - a class under Jmfsb_IntelPackages in the mission config Terminal Class - what to build if this is synchronised to nothing<br>How big a share one hack yields is a CBA setting - 1st Joint Multi-Functional Strike Battalion, Hacking. The package's own contents are mission config, not module attributes: see the wiki.

<details><summary>2 attributes</summary>

- `package`
- `terminal`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_hacking_enabled` | CHECKBOX | Enable Hacking |
| `jmfsb_hacking_condition` | EDITBOX | Hack Condition |
| `jmfsb_hacking_towerClasses` | EDITBOX | Hackable Tower Classes |
| `jmfsb_hacking_droneClasses` | EDITBOX | Downable Drone Classes |
| `jmfsb_hacking_requireISR` | CHECKBOX | Require ISR operator |
| `jmfsb_hacking_scannerVariable` | EDITBOX | Scanner Variable |
| `jmfsb_hacking_alarmVolume` | SLIDER | Scanner Alarm Volume |
| `jmfsb_hacking_remoteEnable` | CHECKBOX | Remote Unit Hack |
| `jmfsb_hacking_remoteRange` | SLIDER | Remote Hack Range (m) |
| `jmfsb_hacking_towerTaor` | EDITBOX | Tower TAOR Marker(s) |
| `jmfsb_hacking_phonePct` | SLIDER | Enemy Cell Phone Carriers (%) |
| `jmfsb_hacking_perHint` | SLIDER | Deposits per Hint |
| `jmfsb_hacking_docChance` | SLIDER | Documents on Bodies (%) |
| `jmfsb_hacking_netFailStep` | SLIDER | Extra detection per net |
| `jmfsb_hacking_netFailWindow` | SLIDER | Detection memory |
| `jmfsb_hacking_netTargets` | LIST | Hackable nets |
| `jmfsb_hacking_cfg_package_share` | SLIDER | Intel package share per hack (%) |

## Functions

<details><summary>61</summary>

- `jmfsb_hacking_fnc_alarmAdd`
- `jmfsb_hacking_fnc_alarmArm`
- `jmfsb_hacking_fnc_alarmRing`
- `jmfsb_hacking_fnc_alarmSilence`
- `jmfsb_hacking_fnc_canDeposit`
- `jmfsb_hacking_fnc_canHack`
- `jmfsb_hacking_fnc_canPlaceDrop`
- `jmfsb_hacking_fnc_canSearch`
- `jmfsb_hacking_fnc_canSpoof`
- `jmfsb_hacking_fnc_depositIntel`
- `jmfsb_hacking_fnc_droneTag`
- `jmfsb_hacking_fnc_hackComplete`
- `jmfsb_hacking_fnc_hackSetting`
- `jmfsb_hacking_fnc_hasPhone`
- `jmfsb_hacking_fnc_hasRadio`
- `jmfsb_hacking_fnc_hasScanner`
- `jmfsb_hacking_fnc_intelHint`
- `jmfsb_hacking_fnc_intelId`
- `jmfsb_hacking_fnc_intelOptions`
- `jmfsb_hacking_fnc_ladderCircle`
- `jmfsb_hacking_fnc_moduleIntelPackage`
- `jmfsb_hacking_fnc_nearestDrone`
- `jmfsb_hacking_fnc_nearestTower`
- `jmfsb_hacking_fnc_nearestWreck`
- `jmfsb_hacking_fnc_netBroken`
- `jmfsb_hacking_fnc_netFailChance`
- `jmfsb_hacking_fnc_onBodyKilled`
- `jmfsb_hacking_fnc_packDrop`
- `jmfsb_hacking_fnc_packageEntries`
- `jmfsb_hacking_fnc_placeDrop`
- `jmfsb_hacking_fnc_popWitness`
- `jmfsb_hacking_fnc_productInstallation`
- `jmfsb_hacking_fnc_productLocateAA`
- `jmfsb_hacking_fnc_productLocateArty`
- `jmfsb_hacking_fnc_productLocateCamp`
- `jmfsb_hacking_fnc_productLocateCoastal`
- `jmfsb_hacking_fnc_productLocateHub`
- `jmfsb_hacking_fnc_productLocateRadar`
- `jmfsb_hacking_fnc_productPackage`
- `jmfsb_hacking_fnc_remoteHackFail`
- `jmfsb_hacking_fnc_renderProduct`
- `jmfsb_hacking_fnc_rfReach`
- `jmfsb_hacking_fnc_scanDevices`
- `jmfsb_hacking_fnc_scannerAlarm`
- `jmfsb_hacking_fnc_scannerClose`
- `jmfsb_hacking_fnc_scannerLayout`
- `jmfsb_hacking_fnc_scannerRead`
- `jmfsb_hacking_fnc_scannerTick`
- `jmfsb_hacking_fnc_scannerTimer`
- `jmfsb_hacking_fnc_scannerToggle`
- `jmfsb_hacking_fnc_searchBody`
- `jmfsb_hacking_fnc_serverPick`
- `jmfsb_hacking_fnc_tabletAction`
- `jmfsb_hacking_fnc_tabletAdvance`
- `jmfsb_hacking_fnc_tabletInRange`
- `jmfsb_hacking_fnc_tabletSelectAction`
- `jmfsb_hacking_fnc_tabletSelectDevice`
- `jmfsb_hacking_fnc_tabletSelectIntel`
- `jmfsb_hacking_fnc_taorType`
- `jmfsb_hacking_fnc_towerInTaor`
- `jmfsb_hacking_fnc_towersInRange`

</details>
