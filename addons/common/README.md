# Common

`jmfsb_common`

The shared floor everything else stands on.

Three things here matter more than the rest. The THREAT BOARD is where every
jmfsb sensor files what it saw, as a belief carrying its own doubt - position,
error, and confidence that decays - so N sensors and M shooters cost N+M wires
instead of N times M. The ALERT BUS is how any system tells players what it just
did to them, because a system you cannot perceive is indistinguishable from bad
luck. And findSite is the placement service every auto-sited asset goes through,
so "radar in a lake" is solved once.

Also hosts JMSB - Core and JMSB - Enemy, the two module classes that are facts
about a mission rather than about one feature.

## The admin surface

`#jmfsb <command>` in any chat channel. Every addon registers its own commands
through `addDebugCommand`; `#jmfsb help` lists what is loaded. The message is
swallowed — it is never broadcast, and a non-admin typing the same thing gets no
reply and no hint that the surface is there.

**Who is an admin.** Anyone who has `#login`-ed, *and* the machine running the
server — a host or a single player is already the admin and has nothing to log in
to. That second half was missing, and `#login` waits on
`serverCommandAvailable "#kick"`, which never becomes true in single player: on a
dev box the flag was never set, so every `#jmfsb` command was silently swallowed.
Because the surface is deliberately silent to non-admins, that looks exactly like
a broken mod rather than a permission you have not got.

## The pre-spawn gate

`taorGate` answers one question — *may this side put something at this
position?* — for every system that spawns at a computed position, because
wrong-side sightings kept coming back one addon at a time and the answer belongs
in one place.

The rule has two halves, and which half applies depends on whether the side
declared any ground of its own:

| | |
|---|---|
| **has a TAOR** | inside it, minus its own blacklist markers. Overlaps with
 other sides' TAORs are *kept* — an insurgency draws the insurgents' ground over
 the players' on purpose, and subtracting it leaves them nowhere to operate |
| **has none** | the whole map, minus everybody else's hostile ground. This is
 the hole the gate was written to close: an undeclared side — usually the
 players' — used to be waved through anywhere, red TAOR included |

A refusal names the caller in the RPT, so the log says which system held its
fire and where. Bulk callers filtering a whole list pass `_quiet` and report a
count instead.

`sideOfFaction` is the other half of `sideFromText`: a faction CLASS
(`OPF_T_F`) turned back into a side, read from `CfgFactionClasses`. ALiVE's
modules hold factions where this mod's modules hold side names, and telling
whose ground is whose starts there.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`

## Ships

54 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_common_isrVariable` | EDITBOX | ISR unit variable |
| `jmfsb_common_boardDebug` | CHECKBOX | Threat Board Debug |

## Functions

<details><summary>54</summary>

- `jmfsb_common_fnc_addDebugCommand`
- `jmfsb_common_fnc_addItem`
- `jmfsb_common_fnc_addMultipleParachutesToObject`
- `jmfsb_common_fnc_addParachuteToObject`
- `jmfsb_common_fnc_alert`
- `jmfsb_common_fnc_bloodType`
- `jmfsb_common_fnc_conditionalPFEH`
- `jmfsb_common_fnc_contactBest`
- `jmfsb_common_fnc_contactGet`
- `jmfsb_common_fnc_contactReport`
- `jmfsb_common_fnc_createPlayerMarker`
- `jmfsb_common_fnc_debugCommand`
- `jmfsb_common_fnc_debugReply`
- `jmfsb_common_fnc_easterDate`
- `jmfsb_common_fnc_edenClassPickLoad`
- `jmfsb_common_fnc_edenClassPickSave`
- `jmfsb_common_fnc_edenDroneFactionLoad`
- `jmfsb_common_fnc_edenDroneFactionSave`
- `jmfsb_common_fnc_enemySide`
- `jmfsb_common_fnc_ensureSafeLanding`
- `jmfsb_common_fnc_findSite`
- `jmfsb_common_fnc_fireBarrage`
- `jmfsb_common_fnc_hudMove`
- `jmfsb_common_fnc_hudPos`
- `jmfsb_common_fnc_hudSetPos`
- `jmfsb_common_fnc_isISR`
- `jmfsb_common_fnc_isOverWater`
- `jmfsb_common_fnc_isUnconscious`
- `jmfsb_common_fnc_lambsOff`
- `jmfsb_common_fnc_listClasses`
- `jmfsb_common_fnc_listFactionDrones`
- `jmfsb_common_fnc_listGroupsWithPlayers`
- `jmfsb_common_fnc_modal`
- `jmfsb_common_fnc_objectFromString`
- `jmfsb_common_fnc_onAlert`
- `jmfsb_common_fnc_onModalClose`
- `jmfsb_common_fnc_onModalOpen`
- `jmfsb_common_fnc_playerSides`
- `jmfsb_common_fnc_putContainerInVehicle`
- `jmfsb_common_fnc_readConfigToNamespace`
- `jmfsb_common_fnc_realisticGrid`
- `jmfsb_common_fnc_renderIntelCircle`
- `jmfsb_common_fnc_renderIntelIcons`
- `jmfsb_common_fnc_returnDepth`
- `jmfsb_common_fnc_runAfterSettingsInit`
- `jmfsb_common_fnc_scatterPosition`
- `jmfsb_common_fnc_setCtrlHeightToText`
- `jmfsb_common_fnc_setDatalink`
- `jmfsb_common_fnc_sideFromText`
- `jmfsb_common_fnc_sideOfFaction`
- `jmfsb_common_fnc_sideToText`
- `jmfsb_common_fnc_sortGroupsBySide`
- `jmfsb_common_fnc_taorGate`
- `jmfsb_common_fnc_uiSquare`

</details>
