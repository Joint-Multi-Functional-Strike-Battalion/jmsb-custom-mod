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

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_
- `jmfsb_notify`
- `jmfsb_support`
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
- `jmfsb_adapter_alive_fnc_hostilityAt`
- `jmfsb_adapter_alive_fnc_installations`
- `jmfsb_adapter_alive_fnc_logisticsHubs`
- `jmfsb_adapter_alive_fnc_nearProfiles`
- `jmfsb_adapter_alive_fnc_objectivesFor`
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
- `jmfsb_adapter_alive_fnc_requestCAS`
- `jmfsb_adapter_alive_fnc_requestFire`
- `jmfsb_adapter_alive_fnc_requestSupply`
- `jmfsb_adapter_alive_fnc_respawnGearManaged`
- `jmfsb_adapter_alive_fnc_sendHint`
- `jmfsb_adapter_alive_fnc_setData`
- `jmfsb_adapter_alive_fnc_supportAssets`
- `jmfsb_adapter_alive_fnc_supportSitrep`
- `jmfsb_adapter_alive_fnc_supportTask`
- `jmfsb_adapter_alive_fnc_supportTypes`
- `jmfsb_adapter_alive_fnc_taorFor`
- `jmfsb_adapter_alive_fnc_virtualFriendlies`

</details>
