# ALiVE Adapter

`jmfsb_adapter_alive`

The only addon allowed to know ALiVE exists (rule 4 of docs/new.md, enforced
by tools/check_invariants.py). Pure translation: ALiVE's hashes and
registries in, plain jmfsb arrays out. Without the ALiVE mod the whole PBO is
skipped and every consumer's guard gets nothing.

Right now it is **slice zero only** (new.md section 9) - the four probes that
must pass in a live mission before any feature is built on top:

    #jmfsb alive.reads      commanders, controltype, TAORs, AA pool
    #jmfsb alive.squad      spawn -> profile -> waypoint, watch it walk in
    #jmfsb alive.fire       one ARTY_REQUEST
    #jmfsb alive.capture    hold a test objective, see the capture event

Each probe prints what it READ as well as what it did, so a wrong assumption
about ALiVE's internals is falsified in one run instead of silently producing
an empty system three phases later.

The probes are admins only (review S7): the chat commands (`#jmfsbreads`,
`#jmfsbsquad`, `#jmfsbfire`, `#jmfsbcapture`, `#jmfsbdamage`, `#jmfsbperf`) go
by `remoteExec` to `probe`, which runs only for an admin by the server's records
(a host and a single player pass; on a dedicated server, `#login` first) and
takes the caller from the sender.

Ready and capture are server hooks, not CBA events (review R1): any client
could raise `jmfsb_adapter_alive_ready` again to restart air defence, leaders,
QRF and UAS, or `jmfsb_adapter_alive_capture` to put a fake FRONT line on every
screen. `whenReady [code, args, fallback]` runs code once ALiVE is up (at
once when it already is), `onCapture [code]` on every objective a commander
takes; both keep their hooks in the server's `localNamespace` and take local
calls only. `jmfsb_adapter_alive_ready` stays as the public flag for readers.

**ALiVE loaded, no commanders = not loaded (user, 2026-11-02: "same as not
loaded").** `ready` waits for the commanders as before. Still none
(`OPCOM_instances` nil or empty) after `READY_GIVE_UP` (300 s): one RPT
warning - `no ALiVE commander after 300s - ALiVE treated as not loaded for
this mission` - and `jmfsb_adapter_alive_absent` is set (server truth in
`localNamespace`, public copy in `missionNamespace`). Every queued hook runs
its `fallback` instead of its code, a later `whenReady` runs the fallback at
once, and `jmfsb_common_fnc_aliveLoaded` answers no for the rest of the
mission. A consumer's fallback is the same branch it runs when this PBO is
not loaded. This addon's own pools and bridge have none: they never start.
Commanders that exist but are still starting up are waited for, no give-up.

ALiVE's presence is common's test on ALiVE's own main PBO names
(`PATCHES_ALIVE`, user: "use the alive main pbo names"); `requiredAddons`
carries the same names as literals - keep the two in step.

## Whose ground is whose

`taorFor` answers "where is this side's ground", and eight systems steer off
it — the pre-spawn gate, air defence, QRF origins, insurgent safe houses, drone
patrols and caches. **A placement belongs to the side its own `faction` names,**
not to whatever it is synchronised to.

That distinction is the whole function. It used to read each commander's
`synchronizedObjects` and treat every placement found there as that commander's
own — which is wrong on any mission that syncs every placement to every OPCOM,
a normal way to build the map and what this collection's Tanoa mission does.
All three sides came back owning `red`, `blue` **and** `green`, every side
therefore "owned" the whole island, and the gate that was supposed to keep
hardware at home passed everything: fifty-five drone patrols in one run, not one
gate refusal, green drones orbiting inside the red TAOR and red ones inside the
green.

A placement with no faction of its own — ALiVE's IED module — falls back to the
commander it is synced to, and only when that is exactly one. Two commanders and
nobody can say whose ground it describes, so it is dropped and said once in the
RPT rather than handed to both.

`#jmfsbreads` prints each side's TAOR and blacklist, which is how you check a
mission's wiring in ten seconds.

## Not a support provider (2026-11-02)

User, 2026-11-02: "we should not be relying on alive support" - "Remove it" -
"if alive is present we integrate - but not the support". The `alive` support
provider is gone: ALiVE's NEO CAS, transport and artillery and the ATO's CAS
row are not support assets, have no `B:SUPPORT:alive:...` box, and take no
card from TAC//MSG. Support is the mod's own providers (`cas`, `support_air`,
`support_fires`, `support_logistics`, `jumpmaster`), the same with or without
ALiVE. Removed with it: the provider's rows, tasks, SITREP and types, its
threads (CAS with CLEARED HOT, the prompts and the check-in; the battery's
call for fire; the transport's lift, circle and landing), the ATO request and
its server hop, and the tactical-lights watch on ALiVE's own aircraft.

**BDA forwarding to ALiVE went with it.** The provider filed a support
thread's BDA to ALiVE's C2ISTAR as a sitrep; nothing does now. Messaging's
own forwarding of reportable cards (CONTACTREP, SITREP - `postReport`) is
unchanged.

What stays with ALiVE support: ALiVE's own tablet still tasks ALiVE's own
combat support where a mission places it, and the LAMBS-off pass on every
airframe tagged `ALIVE_CombatSupport` (`XEH_postInit`) still keeps its
infantry reflexes off them. The enemy's guns are still asked through
`requestFire` (QRF and reaction).

## ALiVE's Advanced Markers for the map marker system (2026-11-01)

jmfsb_maptools' **Map marker system** setting can be ALiVE. Built, not seen in
game. Client side, both:

- `markerOpen [position]` - sets ALiVE's point and "new marker" in
  uiNamespace and opens its Advanced Marker dialog over whatever is open (the
  tablet included). ALiVE opens it itself only on a ctrl+alt press on the
  game's map. False without the Advanced Markers module in the mission - the
  caller then opens its own card. New markers only: editing stays ALiVE's own
  ctrl+alt press on the game's map.
- `markerRemove [marker]` - deletes an ALiVE marker the way ALiVE does, only
  when the store says this player placed it (its Steam id).

## Training hold (2026-11-06)

Place **JMSB - Hold ALiVE** (jmfsb_modules) in a training mission. ALiVE
stands up, then pauses: profiles, OPCOM, CQB, civilians, logistics, ATO.
Nothing spawns near players and no commander gives orders. Nothing that starts
on `whenReady` starts - leaders, QRF, air defence, UAS.

An admin types `#jmfsbalivestart` in chat to start it. Script:
`[false] call jmfsb_adapter_alive_fnc_hold` on the server.

Uses ALiVE's own `pauseModule` / `unPauseModule`. Without ALiVE the module
logs one RPT line and does nothing.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_
- `jmfsb_notify`
- `ALiVE_main` _(external)_
- `ALiVE_x_lib` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

40 functions.

## Functions

<details><summary>40</summary>

- `jmfsb_adapter_alive_fnc_aaTargets`
- `jmfsb_adapter_alive_fnc_artyTargets`
- `jmfsb_adapter_alive_fnc_bumpHostility`
- `jmfsb_adapter_alive_fnc_camps`
- `jmfsb_adapter_alive_fnc_clusterCandidates`
- `jmfsb_adapter_alive_fnc_commanders`
- `jmfsb_adapter_alive_fnc_enemyKnowledge`
- `jmfsb_adapter_alive_fnc_eventBridge`
- `jmfsb_adapter_alive_fnc_eventListener`
- `jmfsb_adapter_alive_fnc_getData`
- `jmfsb_adapter_alive_fnc_hold`
- `jmfsb_adapter_alive_fnc_hostilityAt`
- `jmfsb_adapter_alive_fnc_installations`
- `jmfsb_adapter_alive_fnc_logisticsHubs`
- `jmfsb_adapter_alive_fnc_markerOpen`
- `jmfsb_adapter_alive_fnc_markerRemove`
- `jmfsb_adapter_alive_fnc_nearProfiles`
- `jmfsb_adapter_alive_fnc_objectivesFor`
- `jmfsb_adapter_alive_fnc_onCapture`
- `jmfsb_adapter_alive_fnc_postReport`
- `jmfsb_adapter_alive_fnc_probe`
- `jmfsb_adapter_alive_fnc_profileAlive`
- `jmfsb_adapter_alive_fnc_profileGroup`
- `jmfsb_adapter_alive_fnc_profileIdOf`
- `jmfsb_adapter_alive_fnc_profileIgnore`
- `jmfsb_adapter_alive_fnc_profileObjects`
- `jmfsb_adapter_alive_fnc_profileWaypoint`
- `jmfsb_adapter_alive_fnc_radars`
- `jmfsb_adapter_alive_fnc_ready`
- `jmfsb_adapter_alive_fnc_registerFactionAA`
- `jmfsb_adapter_alive_fnc_registerSite`
- `jmfsb_adapter_alive_fnc_reportIntel`
- `jmfsb_adapter_alive_fnc_requestFire`
- `jmfsb_adapter_alive_fnc_requestSupply`
- `jmfsb_adapter_alive_fnc_respawnGearManaged`
- `jmfsb_adapter_alive_fnc_sendHint`
- `jmfsb_adapter_alive_fnc_setData`
- `jmfsb_adapter_alive_fnc_taorFor`
- `jmfsb_adapter_alive_fnc_virtualFriendlies`
- `jmfsb_adapter_alive_fnc_whenReady`

</details>
