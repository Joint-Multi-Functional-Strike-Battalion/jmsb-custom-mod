# Training

`jmfsb_training`

Spawn and garrison troops in areas on the training map, live. No ALiVE.

The mission holds the info: where, and what.

**JMSB - Garrison Area** module:

- Area: the module's own area, or the Marker attribute.
- Groups: CfgGroups class names, comma separated. One picked at random per
  group. Side comes from the group.
- Group count, patrol chance, hold chance.
- Sync a trigger: spawns each time it fires. No trigger: spawns at mission
  start.

From a script, on the server:

    ["garrison_1", ["O_T_InfSquad", "O_T_InfTeam"], 3] call jmfsb_training_fnc_garrison

Area can be a marker, trigger, area module or `[centre, a, b, angle, rectangle]`.
Returns the groups.

Each group spawns at a random dry spot in the area, then takes buildings with
`CBA_fnc_taskDefend`, centred on the area out to its longer half-axis.

**Target pads** - target vehicles or men, reset from a controller. In the
controller's init field:

    [this, [pad_1, pad_2], ["O_MBT_02_cannon_F", "O_APC_Tracked_02_cannon_F"]] call jmfsb_training_fnc_targetPads

- Pads and classes pair up by index. Pads are objects or their names.
- Targets are locked, empty, unarmed and warm on thermals.
- ACE: Reset targets replaces any that are damaged or gone.

**MOUT / CQB course** - men on spawn points. In the controller's init field:

    [this, "CQB 1", "cqb1", 75, ["O_G_Soldier_F"], 45, [["VR_3DSelector_01_exit_F", ["O_G_Soldier_AR_F"], 60]]] call jmfsb_training_fnc_mout

- Spawn points: objects named `cqb1_0` .. `cqb1_74`, hidden in game.
- Each point is manned at the chance (0-100). A point of a special class can
  get a special man instead.
- Side comes from the man. Men hold their point.
- ACE: Create / Clear. One course per controller.

## TAC//TRAINING app

A tablet app on the training server (PAC `serverId = "training"`). For the
Trainer skill (PAC tag `TRN`) or Sergeant and up. Tile: TRAINING.

**PATIENTS** - casualties for the medics, on stretchers.

- Spawn points: a **JMSB - Medical Training** module per aid station.
  - *Station name* - shown over its points (blank: MEDICAL and its grid).
  - *Spawn points* - variable names of the objects patients go on, comma
    separated, in list order (e.g. `stretcher_1, stretcher_2`). Objects synced
    to the module are added after them.
  - Listed as `<STATION> - 1`, `- 2`... A name with no object is one RPT line.
  - **Sync a laptop** (any class with laptop, computer or terminal in its
    name) for anyone to use - no Trainer skill or rank. ACE on it: MEDICAL
    TRAINING > each of the station's points (FREE or the patient's state) >
    LIGHT / MODERATE / SEVERE / ARREST / RANDOM / REMOVE; random on every free
    point; remove every patient here.
- Preset: LIGHT, MODERATE, SEVERE (unconscious), ARREST, RANDOM.
- CUSTOM: wound kind (GSW, BLAST, STAB, BLUNT) and severity per body part.
- The patient is an unarmed man of the trainer's class, wounded through ACE
  medical. Medics see him on the medic app's NEARBY tab.

**TRAINING AREAS** - one **JMSB - Training Area** module per area. The
module's own area is the area. Its settings:

- **Name** - shown in the app (blank: AREA and its grid).
- **Type**:

| Type | Enemy |
|---|---|
| CQB / shoot house | still on building positions; a few move room to room once shots are near |
| City | teams garrison buildings, a share patrol the streets |
| Patrol | teams patrol |
| Base | guards on positions, a team at the centre, perimeter patrols, static weapons and armed vehicles |

- **Default density**, **Default faction**, **Default patrol radius** - where
  the app starts when the area is picked.
- **Factions offered** - the classes the trainer may pick, comma separated
  (blank: every faction not on his side).

In the app:

- Intel: size, buildings, building positions, how many it holds.
- Enemy: density (light, medium, heavy - the count is worked out from the
  intel), faction, patrol radius past the edge.
- SPAWN, CLEAR, SHOW ON MAP (the area and patrol ring, this machine only).
- Live: status, enemy left, killed, trainees inside.
- After action: first shot to clear, killed, trainees down, who set it up.

**VEHICLE RANGES** - moving targets. One **JMSB - Vehicle Range** module per
range; the module's own area is the range. Its settings:

- **Name** - shown in the app (blank: RANGE and its grid).
- **Vehicles** - CfgVehicles classes, comma separated, used in turn.
- **Direction** - the first leg: N > S, S > N, E > W, W > E or a diagonal.
- **Vehicles at once**, **Speed (km/h)** - where the app starts.
- **Despawn after (minutes)** - 0: only by DESPAWN.

The vehicles spawn side by side at one edge with their own crew, drive to the
far edge, turn round and drive back, edge to edge until destroyed or
despawned. No ammo in the vehicle, no weapons on the crew, the crew never
fights or gets out. Air flies at 100 m.

In the app: direction, how many, speed; SPAWN (RESPAWN replaces them),
DESPAWN (vehicles, wrecks and crews), SHOW ON MAP (the area and an arrow).
Live: moving, destroyed, despawns in.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `cba_ai` _(external)_

## Ships

4 unit classes, 39 functions.

## Eden modules

### JMSB - Garrison Area

`jmfsb_training_moduleGarrison`

CfgGroups class names, comma separated. One is picked at random for each group.

### JMSB - Training Area

`jmfsb_training_moduleArea`

Shown in the TAC
                typeName = 

### JMSB - Medical Training

`jmfsb_training_moduleMedical`

Shown in the app over its points, e.g. AID STATION 1. Blank: MEDICAL and its grid.

### JMSB - Vehicle Range

`jmfsb_training_moduleVehicles`

Shown in the TAC
                typeName = 

## Functions

<details><summary>39</summary>

- `jmfsb_training_fnc_access`
- `jmfsb_training_fnc_app`
- `jmfsb_training_fnc_appAreas`
- `jmfsb_training_fnc_appPatients`
- `jmfsb_training_fnc_appVehicles`
- `jmfsb_training_fnc_areaCasualty`
- `jmfsb_training_fnc_areaClear`
- `jmfsb_training_fnc_areaIntel`
- `jmfsb_training_fnc_areaOf`
- `jmfsb_training_fnc_areaSpawn`
- `jmfsb_training_fnc_areaState`
- `jmfsb_training_fnc_areas`
- `jmfsb_training_fnc_customRows`
- `jmfsb_training_fnc_factionClasses`
- `jmfsb_training_fnc_factions`
- `jmfsb_training_fnc_garrison`
- `jmfsb_training_fnc_groupConfig`
- `jmfsb_training_fnc_medicalLaptops`
- `jmfsb_training_fnc_moduleArea`
- `jmfsb_training_fnc_moduleGarrison`
- `jmfsb_training_fnc_moduleMedical`
- `jmfsb_training_fnc_moduleVehicles`
- `jmfsb_training_fnc_mout`
- `jmfsb_training_fnc_moutClear`
- `jmfsb_training_fnc_moutCreate`
- `jmfsb_training_fnc_patientClear`
- `jmfsb_training_fnc_patientSpawn`
- `jmfsb_training_fnc_patientWounds`
- `jmfsb_training_fnc_resetPads`
- `jmfsb_training_fnc_resolve`
- `jmfsb_training_fnc_showArea`
- `jmfsb_training_fnc_spawnPadTarget`
- `jmfsb_training_fnc_stretchers`
- `jmfsb_training_fnc_targetPads`
- `jmfsb_training_fnc_tile`
- `jmfsb_training_fnc_vehClear`
- `jmfsb_training_fnc_vehRanges`
- `jmfsb_training_fnc_vehSpawn`
- `jmfsb_training_fnc_vehState`

</details>
