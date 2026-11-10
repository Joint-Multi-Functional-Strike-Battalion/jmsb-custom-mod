#include "script_component.hpp"
/*
 * Author: YonV
 * Spawns groups in an area and garrisons its buildings. The training map's
 * live spawner: the mission says where (a marker, a trigger, the Garrison
 * Area module) and what (CfgGroups classes), and calls this whenever it wants
 * troops there - from a trigger, a script or the server debug console. No
 * ALiVE.
 *
 * Each group spawns at a random dry spot in the area, then takes buildings
 * with CBA_fnc_taskDefend: centred on the area, out to its longer half-axis.
 * Side comes from the group's own config.
 *
 * Arguments:
 * 0: Area - marker name, trigger, area module, or [centre, a, b, angle, rectangle] <STRING, OBJECT, ARRAY>
 * 1: Groups - CfgGroups class names or configs; one picked at random per group <ARRAY>
 * 2: How many groups <NUMBER> (optional, default 1)
 * 3: Chance each man patrols instead of taking a building <NUMBER> (optional, default 0.2)
 * 4: Chance each man holds his building in combat <NUMBER> (optional, default 0.5)
 *
 * Return Value:
 * Groups spawned <ARRAY>
 *
 * Example:
 * ["garrison_1", ["O_T_InfSquad", "O_T_InfTeam"], 3] call jmfsb_training_fnc_garrison
 *
 * Public: Yes
 */

params [
    ["_area", "", ["", objNull, []]],
    ["_groups", [], [[]]],
    ["_count", 1, [0]],
    ["_patrol", DEFAULT_PATROL, [0]],
    ["_hold", DEFAULT_HOLD, [0]]
];

if (!isServer) exitWith {
    WARNING("garrison: server only");
    []
};

private _shape = [_area] call FUNC(areaOf);
if (_shape isEqualTo []) exitWith {
    WARNING_1("garrison: no such area %1",_area);
    []
};
_shape params ["_centre", "_a", "_b", "_angle", "_rect"];

private _configs = (_groups apply {[_x] call FUNC(groupConfig)}) select {!isNull _x};
if (_configs isEqualTo []) exitWith {
    WARNING_1("garrison: no CfgGroups class found in %1",_groups);
    []
};

private _radius = _a max _b;
private _spawned = [];

for "_i" from 1 to _count do {
    private _cfg = selectRandom _configs;
    private _side = (getNumber (_cfg >> "side")) call BIS_fnc_sideType;

    private _pos = _centre;
    for "_try" from 1 to SPAWN_TRIES do {
        private _p = _centre getPos [_radius * sqrt random 1, random 360];
        if (_p inArea [_centre, _a, _b, _angle, _rect] && {!surfaceIsWater _p}) exitWith {
            _pos = _p;
        };
    };

    private _grp = [_pos, _side, _cfg] call BIS_fnc_spawnGroup;
    if (!isNull _grp) then {
        _grp deleteGroupWhenEmpty true;

        [_grp, _centre, _radius, DEFEND_THRESHOLD, _patrol, _hold] call CBA_fnc_taskDefend;

        // The mod's spawn bus, as the AI Spawner raises it.
        [QEGVAR(common,groupSpawned), [_grp, [], [false]]] call CBA_fnc_localEvent;

        _spawned pushBack _grp;
    };
};

INFO_3("garrison: %1 group(s) in %2, %3 m",count _spawned,_area,round _radius);

_spawned
