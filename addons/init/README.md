# Init

`jmfsb_init`

The two-argument INFO/WARNING/ERROR/LOG the Roomba scripts were written against, plus the notification colours and the logistics shorthand. Included AFTER jmfsb's macros so the #undef in there lands on the right definitions.

**Attendance is the server's (review S7).** `#attendance`, the Zeus "Take
attendance" module and Call Endex ask by `remoteExec`
(`jmfsb_init_fnc_srvAttendance`); the server answers only an admin by its own
records or a player holding a curator module, and sends the names back to his
machine alone (`jmfsb_init_fnc_attendance`, taken only from the server).

**Review R1.** The connection log is written by the server's own
PlayerConnected handler (`jmfsb_init_fnc_logPlayer`, local calls only). It was
the `jmfsb_log_player` CBA event, which let any client forge attendance. An ACM
casualty evacuation goes by `remoteExec` to `jmfsb_init_fnc_srvEvacuated`, which
takes a group slot away only from the sender's own unit or a non-player body.
It was the `YMF_casualtyEvacuatedserver` CBA event, which let any client take
any player out of his group.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_diag`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

20 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_init_QEGVAR(Settings,setMissionType)` | LIST | Mission Type |
| `jmfsb_init_QEGVAR(Settings,setAiSystemDifficulty)` | LIST | AI Setting |
| `jmfsb_init_QEGVAR(Settings,showDiaryRecords)` | CHECKBOX | Documents |
| `jmfsb_init_QEGVAR(Settings,setPlayerRank)` | CHECKBOX | Rank |
| `jmfsb_init_QEGVAR(Settings,allowInsigniaApplication)` | CHECKBOX | Insignia |
| `jmfsb_init_QEGVAR(Settings,addEarplugs)` | CHECKBOX | Apply Earplugs |
| `jmfsb_init_QEGVAR(Settings,enableStagingSystem)` | CHECKBOX | Enable |
| `jmfsb_init_QEGVAR(Settings,enableVehicleSystem)` | CHECKBOX | Enable |
| `jmfsb_init_QEGVAR(Settings,enableVehiclePylon)` | CHECKBOX | Pylon |
| `jmfsb_init_QEGVAR(Settings,enableVehicleInventory)` | CHECKBOX | Inventory |
| `jmfsb_init_QEGVAR(Settings,vehicleFactions)` | EDITBOX | Factions |
| `jmfsb_init_QEGVAR(Settings,jumpSimulation)` | LIST | Simulation Type |
| `jmfsb_init_QEGVAR(Settings,jumpSimulationNVG)` | CHECKBOX | Include Night Vision Googles |
| `jmfsb_init_QEGVAR(Settings,jumpSimulationGlasses)` | CHECKBOX | Include Non-combat Googles |
| `jmfsb_init_QEGVAR(Settings,jumpSimulationHat)` | CHECKBOX | Include Non-combat Headgear |
| `jmfsb_init_QEGVAR(Settings,radarNetwork)` | CHECKBOX | Radar network |
| `jmfsb_init_QEGVAR(Settings,radarClasses)` | EDITBOX | Vehicle classes |

## Functions

<details><summary>20</summary>

- `jmfsb_init_fnc_aiSkill`
- `jmfsb_init_fnc_attendance`
- `jmfsb_init_fnc_chatCommands`
- `jmfsb_init_fnc_diary`
- `jmfsb_init_fnc_eventHandlers`
- `jmfsb_init_fnc_logPlayer`
- `jmfsb_init_fnc_logistics`
- `jmfsb_init_fnc_mapDrawing`
- `jmfsb_init_fnc_message`
- `jmfsb_init_fnc_missionConfigsReady`
- `jmfsb_init_fnc_playerpost`
- `jmfsb_init_fnc_pylons`
- `jmfsb_init_fnc_radarNetwork`
- `jmfsb_init_fnc_skillAdjustment`
- `jmfsb_init_fnc_srvAttendance`
- `jmfsb_init_fnc_srvEvacuated`
- `jmfsb_init_fnc_staging`
- `jmfsb_init_fnc_unitPatch`
- `jmfsb_init_fnc_vehicle`
- `jmfsb_init_fnc_zenModuels`

</details>
