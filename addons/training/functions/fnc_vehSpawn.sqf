#include "script_component.hpp"
/*
 * Author: YonV
 * Spawns a vehicle range's moving targets (user, 2026-11-07): its vehicles,
 * crewed, with no ammo, side by side at one edge, driving across to the far
 * edge, turning round and driving back - edge to edge until destroyed or
 * despawned (a MOVE - MOVE - CYCLE loop). Whatever the range had is removed
 * first. Server only - the app sends it.
 *
 * The run is a straight line through the area along the heading; its ends
 * are where that line leaves the area, VR_EDGE_INSET in. Side by side lines
 * are VR_LANE_GAP apart; one too short for a run drives the centre line.
 *
 * The crew cannot fight: no ammo in the vehicle, no weapons on the men, no
 * targeting, never get out, careless. Air is spawned flying at VR_FLY_HEIGHT.
 *
 * Arguments:
 * 0: Range key <STRING>
 * 1: Direction index into VR_DIRECTIONS <NUMBER>
 * 2: How many <NUMBER>
 * 3: Speed, km/h <NUMBER>
 * 4: Set by, a name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["vr_1200_3400", 0, 2, 30, "Trainer"] call jmfsb_training_fnc_vehSpawn
 *
 * Public: No
 */

params [["_key", "", [""]], ["_dirIdx", 0, [0]], ["_count", VR_DEFAULT_COUNT, [0]], ["_speed", VR_DEFAULT_SPEED, [0]], ["_by", "", [""]]];

if (!isServer) exitWith {};
private _ranges = [] call FUNC(vehRanges);
private _range = _ranges param [_ranges findIf {(_x # 0) isEqualTo _key}, []];
if (_range isEqualTo []) exitWith {WARNING_1("vehicle range %1 not found",_key)};
_range params ["", "", "_name", "_centre", "_a", "_b", "_angle", "_rect", "_settings"];
_settings params ["_classes", "", "", "", "_despawnMin"];
if (_classes isEqualTo []) exitWith {WARNING_1("vehicle range '%1' has no vehicles to spawn",_name)};

[_key] call FUNC(vehClear);

(VR_DIRECTIONS param [_dirIdx, VR_DIRECTIONS # 0]) params ["_dirLabel", "_heading"];
_count = (round _count) max 1 min VR_MAX_COUNT;
_speed = _speed max VR_SPEED_STEP min VR_MAX_SPEED;
private _shape = [_centre, _a, _b, _angle, _rect];
private _along = [sin _heading, cos _heading, 0];
private _across = [cos _heading, -(sin _heading), 0];
private _reach = 2 * (_a max _b);

// how far from _from along _dir the area goes, in VR_STEP steps
private _fnc_edge = {
    params ["_from", "_dir"];
    private _d = 0;
    while {_d < _reach && {(_from vectorAdd (_dir vectorMultiply (_d + VR_STEP))) inArea _shape}} do {
        _d = _d + VR_STEP;
    };
    _d
};
// [start, end] of the run through the line offset _off across, or [] if too short
private _fnc_run = {
    params ["_off"];
    private _mid = _centre vectorAdd (_across vectorMultiply _off);
    if !(_mid inArea _shape) exitWith {[]};
    private _back = ([_mid, _along vectorMultiply -1] call _fnc_edge) - VR_EDGE_INSET;
    private _ahead = ([_mid, _along] call _fnc_edge) - VR_EDGE_INSET;
    if (_back + _ahead < VR_MIN_RUN) exitWith {[]};
    [_mid vectorAdd (_along vectorMultiply -_back), _mid vectorAdd (_along vectorMultiply _ahead)]
};

private _centreRun = [0] call _fnc_run;
if (_centreRun isEqualTo []) exitWith {WARNING_1("vehicle range '%1' is too small for a run",_name)};

private _vehicles = [];
for "_i" from 0 to (_count - 1) do {
    private _run = [(_i - (_count - 1) / 2) * VR_LANE_GAP] call _fnc_run;
    if (_run isEqualTo []) then {_run = _centreRun};
    _run params ["_start", "_end"];
    private _class = _classes select (_i mod count _classes);
    private _air = _class isKindOf "Air";
    private _veh = createVehicle [_class, _start, [], 0, ["NONE", "FLY"] select _air];
    _veh setDir _heading;
    if (_air) then {_veh flyInHeight VR_FLY_HEIGHT};
    _veh setVehicleAmmo 0;
    _veh allowCrewInImmobile true;
    _veh setVariable [QGVAR(range), _key, true];

    private _grp = createVehicleCrew _veh;
    _grp deleteGroupWhenEmpty true;
    {
        _x setVariable [QGVAR(range), _key, true];
        removeAllWeapons _x;
        _x allowFleeing 0;
        private _unit = _x;
        {_unit disableAI _x} forEach VR_DISABLE_AI;
    } forEach crew _veh;
    _grp setBehaviourStrong "CARELESS";
    _grp setCombatMode "BLUE";
    _grp setSpeedMode "LIMITED";
    _veh forceSpeed (_speed / VR_KMH_PER_MS);

    // edge to edge for good: out, back, and round again
    {
        _x params ["_at", "_type"];
        private _wp = _grp addWaypoint [_at, 0];
        _wp setWaypointType _type;
        _wp setWaypointCompletionRadius VR_WP_RADIUS;
    } forEach [[_end, "MOVE"], [_start, "MOVE"], [_end, "CYCLE"]];

    _vehicles pushBack _veh;
};

private _despawnAt = [-1, serverTime + _despawnMin * SECONDS_PER_MINUTE] select (_despawnMin > 0);
private _state = [_key, "spawned", [_vehicles, _by, _dirLabel, _speed, _despawnAt]] call FUNC(vehState);
if (_despawnAt > 0) then {
    // only this spawn's: a later SPAWN or DESPAWN makes it a no-op
    [{
        params ["_key", "_startedAt"];
        private _now = [_key] call FUNC(vehState);
        if ((_now # 0) isEqualTo "live" && {(_now # 2) isEqualTo _startedAt}) then {[_key] call FUNC(vehClear)};
    }, [_key, _state # 2], _despawnMin * SECONDS_PER_MINUTE] call CBA_fnc_waitAndExecute;
};
INFO_5("vehicle range '%1': %2 x %3, %4 at %5 km/h",_name,count _vehicles,_classes,_dirLabel,_speed);
