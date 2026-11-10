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

**The server checks every hack and every deposit** (review S7, 2026-10-31).
The tablet runs the bar and rolls what only costs the hacker (the fail roll,
a net's detection roll); everything else is the server's, reached by
`remoteExec` - never a CBA event, which carries no sender:

- START sends `fnc_srvHackStart`: the server checks the sender may hack that
  device (`fnc_srvMayHack`) and starts its own clock on it.
- Completion sends `fnc_srvHackComplete`. The server takes the operator from
  the sending machine and his side from his group, re-runs `fnc_srvMayHack` -
  the hack gate, the kind's range, that the object really is a hostile drone,
  a downed one, a tower or emitter in its TAOR, or a net the mission lets you
  break, and that it is not broken already or a tower still cooling - and
  needs the hack to have started at least 90% of the kind's clock
  (`fnc_hackDuration`) ago. The product must be one the device offers. Only
  then does it down the drone, mark the net or wreck, book the tower, send
  the failure package or the SPOOF, or pull the product at the device's own
  position. A refusal is said on the sender's screen. What is broken and when
  each tower was last hacked is kept in `localNamespace` on the server; the
  public flags on the devices are for the screens.
- A deposit sends `fnc_srvDeposit` with the drop only. The server checks the
  drop is a real intel drop within 8 m of the sender, counts the intel his
  unit carries, banks that and has his machine remove the items
  (`fnc_depositTake`, taken only from the server). One deposit per man every
  3 s.
- A START on a leaders' internet pop is checked for civilian witnesses in
  `fnc_srvHackStart` (`fnc_popWitness`, on the server, once per pop per
  minute). The `popSeen` CBA event is gone.
- The tally (items banked, hint tier, ids hinted) and the hint's side are the
  server's, in `localNamespace`; `jmfsb_hacking_banked` in missionNamespace
  is a public copy for screens.

**The server's pushes are taken only from the server** (review S7). Products
go out by `fnc_sendProduct` to `fnc_renderProduct`, the result line by
`fnc_pickResult`, the HACK board's RF answer by `fnc_rfReached` (to the asker
alone), the alarm ring by `fnc_alarmRing` - each by `remoteExec`, each
checking `jmfsb_common_fnc_fromServer`. The `render`, `pickResult`,
`rfReached` and `alarmRing` CBA events are gone, and so is `product`:
jmfsb_leaders' safe-house circle and interrogation reveal go through
`fnc_sendProduct` too. The `rfReachAsk` server
event stays (the tacpad HACK board raises it): it carries no trust - the
answer is the named man's own reach, sent to his machine - and the server
answers it at most every 2 s per man.

**Scanner alarms** are armed, deleted and cleared by `remoteExec`
(`fnc_srvAlarmAdd`, `fnc_srvAlarmDelete`, `fnc_srvAlarmsClear`). The setter's
name is the sender's; a delay is clamped to 1 s - 1 day, and at most 20 are
armed. The list is the server's, in `localNamespace`; `jmfsb_hacking_alarms`
is a copy for screens (`fnc_alarmPublish`). The tacpad TIMER app uses the same
functions, so the old `alarmAdd` CBA event and the published-list delete path
are gone; a host deleting from TIMER reaches the server's list too.

**Hack progress** on a device (`jmfsb_hacking_progress`) is set locally every
tick and published only at each quarter (review P8): the hacker resumes
exactly, another operator from the last quarter.

**Body intel on every machine** (review B20). The killed handler runs where
the man is local - a headless client's AI too - and sends the death to the
server, which takes it only from the machine that owned him and decides once.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `ace_interact_menu` _(external)_
- `ace_common` _(external)_
- `jmfsb_notify`
- `jmfsb_common`
- `cba_xeh` _(external)_

## Ships

2 unit classes, 4 weapon/item classes, 70 functions.

## Eden modules

### JMSB - Intel Package

`jmfsb_moduleIntelPackage`, category jmfsb_modules

Puts an intel package on a device. Hacking that device hands over a share of it.<br>Package - a class under Jmfsb_IntelPackages in the mission config Terminal Class - what to build if this is synchronised to nothing<br>How big a share one hack yields is a CBA setting - JMSB - EW, Drones & Intel, Hacking. The package's own contents are mission config, not module attributes: see the wiki.

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

<details><summary>70</summary>

- `jmfsb_hacking_fnc_alarmAdd`
- `jmfsb_hacking_fnc_alarmArm`
- `jmfsb_hacking_fnc_alarmPublish`
- `jmfsb_hacking_fnc_alarmRing`
- `jmfsb_hacking_fnc_alarmSilence`
- `jmfsb_hacking_fnc_canDeposit`
- `jmfsb_hacking_fnc_canHack`
- `jmfsb_hacking_fnc_canPlaceDrop`
- `jmfsb_hacking_fnc_canSearch`
- `jmfsb_hacking_fnc_canSpoof`
- `jmfsb_hacking_fnc_depositIntel`
- `jmfsb_hacking_fnc_depositTake`
- `jmfsb_hacking_fnc_droneTag`
- `jmfsb_hacking_fnc_hackComplete`
- `jmfsb_hacking_fnc_hackDuration`
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
- `jmfsb_hacking_fnc_pickResult`
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
- `jmfsb_hacking_fnc_rfReached`
- `jmfsb_hacking_fnc_scanDevices`
- `jmfsb_hacking_fnc_scannerAlarm`
- `jmfsb_hacking_fnc_scannerRead`
- `jmfsb_hacking_fnc_searchBody`
- `jmfsb_hacking_fnc_selectTarget`
- `jmfsb_hacking_fnc_sendProduct`
- `jmfsb_hacking_fnc_serverPick`
- `jmfsb_hacking_fnc_srvAlarmAdd`
- `jmfsb_hacking_fnc_srvAlarmDelete`
- `jmfsb_hacking_fnc_srvAlarmsClear`
- `jmfsb_hacking_fnc_srvDeposit`
- `jmfsb_hacking_fnc_srvHackComplete`
- `jmfsb_hacking_fnc_srvHackStart`
- `jmfsb_hacking_fnc_srvMayHack`
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
