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

**Who is an admin - the server decides (2026-10-31, code review S1-S7).** The
server alone answers it, from its own records (`adminCheck`): the machine running
the server (a host or a single player has nothing to log in to), anyone logged in
with `#login`, and the Steam ids on the server's admin list. That list lives in
the server's `localNamespace`, which is not networked, and is built from sources
(`adminSource`): the mod's list and the console's grants (adminpanel), TAC//PAC's
admins (pac). The admin panel's testing switch is read once when the server
loads.

The public flag `jmfsb_common_isAdmin` is the server's copy for screens. A
client asks for it at start, after `#login` / `#logout` and on a change of unit
(`adminClaim`); the server sets it (`adminFlags`). No server check reads it: a
client can still set it on himself.

**Who sent a request.** CBA events carry no sender. A request that needs trust
comes by `remoteExec`, and the server function checks at its top, before any
`spawn`:

- `sender` - the sending machine, its player and Steam id, from
  `remoteExecutedOwner`, never from the arguments;
- `senderIs [unit]` - the unit a request names is the sender's own;
- `senderIsAdmin` - the sender is an admin by the server's records;
- `fromServer` - on a client, the call came from the server (the server checks,
  then forwards by `remoteExec`).

The ALERT BUS follows it too: the server's `alert` sends `onAlert` by
`remoteExec` to the players it concerns, and `onAlert` takes a remote call only
from the server - a machine's own alert (the tacpad's TIMER) is a plain local
call. It was the `alert` CBA event, which any client could raise to put a red
danger popup on every screen.

The `#jmfsb` surface follows the same rule: only the typer's machine runs a
command, and a server command goes by `remoteExec` to `debugRunServer`, which
checks the sender.

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

**With or without ALiVE (2026-11-02).** `aliveLoaded` is the one test and
writes `<feature>: ALiVE not loaded - <what instead>` to the RPT once per
feature. ALiVE is loaded when ALiVE's own main PBOs are - every CfgPatches
class in `PATCHES_ALIVE` (`ALiVE_main`, `ALiVE_x_lib`, script_component.hpp;
user: "use the alive main pbo names") - and the adapter's class with them, so
a yes means the adapter's functions exist. ALiVE loaded with no commanders is
not loaded (user: "same as not loaded"): once the adapter gives up on them
(`jmfsb_adapter_alive_absent`) `aliveLoaded` says no, and its line reads
`ALiVE loaded with no commanders - treated as not loaded`. With ALiVE the next
four are ALiVE's answers unchanged; without it - or once ALiVE is declared
absent - they are the mission's own:

| Function | With ALiVE | Without ALiVE |
|---|---|---|
| `groundFor` | the adapter's `taorFor` | area markers named `jmfsb_taor_west` / `_east` / `_guer` (anything may follow), `jmfsb_black_<side>` kept out |
| `settlements` | ALiVE's settlement clusters | the map's capital, city and village locations |
| `hostileCommander` | the first ALiVE commander hostile to a side | the mission's enemy (`enemySide`) when hostile, no control type |
| `sideFaction` | - | the most common faction among a side's AI, or a named unit's |

`taorGate` reads `groundFor`, so the pre-spawn gate holds without ALiVE too.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`

## Ships

76 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_common_isrVariable` | EDITBOX | ISR unit variable |
| `jmfsb_common_perfLog` | CHECKBOX | Log tick timings |
| `jmfsb_common_boardDebug` | CHECKBOX | Threat Board Debug |

## Functions

<details><summary>76</summary>

- `jmfsb_common_fnc_addDebugCommand`
- `jmfsb_common_fnc_addItem`
- `jmfsb_common_fnc_addMultipleParachutesToObject`
- `jmfsb_common_fnc_addParachuteToObject`
- `jmfsb_common_fnc_adminCheck`
- `jmfsb_common_fnc_adminClaim`
- `jmfsb_common_fnc_adminFlags`
- `jmfsb_common_fnc_adminSource`
- `jmfsb_common_fnc_alert`
- `jmfsb_common_fnc_aliveLoaded`
- `jmfsb_common_fnc_artyGroups`
- `jmfsb_common_fnc_bloodType`
- `jmfsb_common_fnc_conditionalPFEH`
- `jmfsb_common_fnc_contactBest`
- `jmfsb_common_fnc_contactGet`
- `jmfsb_common_fnc_contactReport`
- `jmfsb_common_fnc_createPlayerMarker`
- `jmfsb_common_fnc_daysFromCivil`
- `jmfsb_common_fnc_debugCommand`
- `jmfsb_common_fnc_debugReply`
- `jmfsb_common_fnc_debugRunServer`
- `jmfsb_common_fnc_easterDate`
- `jmfsb_common_fnc_edenClassPickLoad`
- `jmfsb_common_fnc_edenClassPickSave`
- `jmfsb_common_fnc_edenDroneFactionLoad`
- `jmfsb_common_fnc_edenDroneFactionSave`
- `jmfsb_common_fnc_enemySide`
- `jmfsb_common_fnc_ensureSafeLanding`
- `jmfsb_common_fnc_findSite`
- `jmfsb_common_fnc_fireBarrage`
- `jmfsb_common_fnc_fromServer`
- `jmfsb_common_fnc_groundFor`
- `jmfsb_common_fnc_hostileCommander`
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
- `jmfsb_common_fnc_onBarrage`
- `jmfsb_common_fnc_onModalClose`
- `jmfsb_common_fnc_onModalOpen`
- `jmfsb_common_fnc_perfAdd`
- `jmfsb_common_fnc_perfReport`
- `jmfsb_common_fnc_playerSides`
- `jmfsb_common_fnc_putContainerInVehicle`
- `jmfsb_common_fnc_readConfigToNamespace`
- `jmfsb_common_fnc_realisticGrid`
- `jmfsb_common_fnc_renderIntelCircle`
- `jmfsb_common_fnc_renderIntelIcons`
- `jmfsb_common_fnc_returnDepth`
- `jmfsb_common_fnc_runAfterSettingsInit`
- `jmfsb_common_fnc_scatterPosition`
- `jmfsb_common_fnc_secret`
- `jmfsb_common_fnc_secretSet`
- `jmfsb_common_fnc_secretStatus`
- `jmfsb_common_fnc_sender`
- `jmfsb_common_fnc_senderIs`
- `jmfsb_common_fnc_senderIsAdmin`
- `jmfsb_common_fnc_setCtrlHeightToText`
- `jmfsb_common_fnc_setDatalink`
- `jmfsb_common_fnc_settlements`
- `jmfsb_common_fnc_sideFaction`
- `jmfsb_common_fnc_sideFromText`
- `jmfsb_common_fnc_sideOfFaction`
- `jmfsb_common_fnc_sideToText`
- `jmfsb_common_fnc_sortGroupsBySide`
- `jmfsb_common_fnc_taorGate`
- `jmfsb_common_fnc_uiSquare`

</details>
