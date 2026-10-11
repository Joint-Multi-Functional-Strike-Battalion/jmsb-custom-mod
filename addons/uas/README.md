# UAS

`jmfsb_uas`

Patrol drones and the supply that limits them.

**One module is one patrol.** Place a *JMSB - Drone Patrol* module in Eden or in
Zeus, resize it, and it says everything about that patrol: whose drones, how
many, which airframe, and whether a drone that sees somebody calls artillery on
them. Several patrols, several modules. In jmfsb this addon flew drones over each
ALiVE commander's own objectives with one shared per-side ceiling; a number on
the module you placed is a better answer than a ceiling shared across the map,
so the module is the unit of work here.

**ALiVE objectives can become zones too, and it is off by default.** Turn on
*Patrol ALiVE objectives* under 1st Joint Multi-Functional Strike Battalion / Drones and
`FUNC(zonesFromAlive)` takes a share of each commander's objectives - capped -
and appends them to `GVAR(zones)` as ordinary entries, once, when the campaign
comes up. Every function here treats them exactly like a drawn module, because
they are the same shape. They ADD to the modules you placed rather than
replacing them, and they never call for artillery: that is a decision about one
piece of ground, so it lives on a module.

**Supply caches** are real crates inside those zones, unmarked and unhinted -
finding them is what the intel economy is for. Kill one and that side's airframe
ceiling drops for a random window: the sky visibly thins, then comes back.
Outages extend rather than stack, so supply raids are raids and not a win button.

**Nobody near, nothing flying.** A patrol exists to be met. One orbiting ground
four kilometres from the nearest player is an airframe, a crew and an AI pilot
simulated for an audience of nobody, so a zone with nobody inside 3.2 km is not
patrolled and the patrols whose audience has left are retired. An empty map costs
nothing.

**A patrol never grows past its own number**, and the supply outage only ever
reduces it: while a side's cache is down every one of its patrols thins to one
airframe, then fills again when the window closes. Outage windows and the cache
count are CBA settings under *1st Joint Multi-Functional Strike Battalion > Drones*; everything else about a
patrol is on its own module.

A drone that actually sees a player - `knowsAbout`, not proximity - reports it
down the same path a failed hack takes.

    #jmfsbuas    ceilings, patrol counts, live outages

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

4 unit classes, 19 functions.

## Eden modules

### JMSB - Drone Patrol

`jmfsb_moduleDronePatrol`, category jmfsb_modules

One patrol. Resize it - the area is the ground the drones fly over.<br>Side - whoever is hostile to the players, worked out from the mission's side relations Drones - how many airframes this patrol keeps up Drone Class - empty flies the enemy side's own<br>Artillery On Detect - a drone that sees somebody shells where it saw them Rounds / Scatter (m) / Cooldown (s) - the size of that mission and its gap<br>A module never resized is one 800 m orbit. Nobody within 3.2 km, nothing flies.

<details><summary>5 attributes</summary>

- `artyCooldown`
- `artyRounds`
- `artyScatter`
- `droneClass`
- `droneCount`

</details>

### JMSB - Drone Swarm

`jmfsb_moduleDroneSwarm`, category jmfsb_modules

A swarm, launched where you place it. Trigger it to launch on cue.<br>Airframe - which drone. Limited by the Swarm Airframes setting Drones - 2 to 12 Action - Impact dives on this module; Circle orbits it Spawn Min / Max (m) - how far out they appear and fly in from Side - the fallback crew's side<br>Resize the module to set the orbit radius. Impact ignores the area.

<details><summary>6 attributes</summary>

- `spawnMax`
- `spawnMin`
- `swarmAction`
- `swarmClass`
- `swarmCount`
- `swarmSide`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_uas_windowMin` | SLIDER | Outage minimum (s) |
| `jmfsb_uas_windowMax` | SLIDER | Outage maximum (s) |
| `jmfsb_uas_cachesPerSide` | SLIDER | Supply caches per side |
| `jmfsb_uas_swarmClasses` | EDITBOX | Swarm airframes |
| `jmfsb_uas_aliveZones` | CHECKBOX | Patrol ALiVE objectives |
| `jmfsb_uas_aliveZoneShare` | SLIDER | ALiVE objectives patrolled (%) |
| `jmfsb_uas_aliveZoneMax` | SLIDER | Max ALiVE zones per side |
| `jmfsb_uas_aliveZoneRadius` | SLIDER | ALiVE zone radius (m) |
| `jmfsb_uas_aliveZoneDrones` | SLIDER | Airframes per ALiVE zone |

## Functions

<details><summary>19</summary>

- `jmfsb_uas_fnc_cacheDown`
- `jmfsb_uas_fnc_ceilingFor`
- `jmfsb_uas_fnc_factionUav`
- `jmfsb_uas_fnc_iedDrone`
- `jmfsb_uas_fnc_livePatrols`
- `jmfsb_uas_fnc_moduleDronePatrol`
- `jmfsb_uas_fnc_moduleDroneSwarm`
- `jmfsb_uas_fnc_placeCaches`
- `jmfsb_uas_fnc_planPatrols`
- `jmfsb_uas_fnc_playerNear`
- `jmfsb_uas_fnc_respondTo`
- `jmfsb_uas_fnc_spotSweep`
- `jmfsb_uas_fnc_standDown`
- `jmfsb_uas_fnc_start`
- `jmfsb_uas_fnc_swarmCircle`
- `jmfsb_uas_fnc_swarmImpact`
- `jmfsb_uas_fnc_topUp`
- `jmfsb_uas_fnc_zonesFor`
- `jmfsb_uas_fnc_zonesFromAlive`

</details>
