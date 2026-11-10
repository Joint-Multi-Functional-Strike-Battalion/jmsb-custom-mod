#include "script_component.hpp"
/*
 * Author: YonV
 * Once a second: the markers, and what the player's movement means against
 * the side's measures (design c2_app.per_type) - each an event he can report
 * with the action key (numpad 9) for REPORT_WINDOW seconds:
 *
 *     phase line   crossed it        "CROSSED PL BLUE"
 *     boundary     crossed it        a warning - out of or into his area
 *     LOA          within WARN_RANGE a warning - do not cross; crossed, louder
 *     objective    stepped inside    "ON OBJ RED"
 *     rally point  within NEAR_RANGE "AT RP 1"
 *     checkpoint   within NEAR_RANGE "PASSED CP 3"
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_c2_fnc_tick
 *
 * Public: No
 */

[] call FUNC(markers);
if (!alive player) exitWith {};

private _now = getPosATL player;
private _was = GVAR(lastPos);
GVAR(lastPos) = _now;
if (_was isEqualTo []) exitWith {};

private _fnc_event = {
    params ["_text", "_colour", ["_report", true]];
    [NOTE_TITLE, [_text, _text + "  -  9: REPORT"] select _report, _colour] call EFUNC(notify,notify);
    if (_report) then {GVAR(event) = [_text, CBA_missionTime]};
};
private _fnc_crossed = {
    params ["_points"];
    private _hit = false;
    for "_i" from 0 to (count _points - 2) do {
        if ([_was, _now, _points # _i, _points # (_i + 1)] call FUNC(intersects)) exitWith {_hit = true};
    };
    _hit
};

{
    _x params ["_mid", "_type", "_name", "_points", "", "", "", "_side"];
    if (_side isNotEqualTo side group player) then {continue};
    private _inside = GVAR(inside) getOrDefault [_mid, false];
    switch (_type) do {
        case "phase_line": {
            if ([_points] call _fnc_crossed) then {[format ["CROSSED PL %1", _name], NOTE_COLOUR] call _fnc_event};
        };
        case "boundary": {
            if ([_points] call _fnc_crossed) then {[format ["CROSSED BOUNDARY %1", _name], NOTE_WARN, false] call _fnc_event};
        };
        case "loa": {
            if ([_points] call _fnc_crossed) then {[format ["PAST LOA %1 - GO BACK", _name], NOTE_WARN] call _fnc_event};
            private _close = (([_now, _points, false] call FUNC(nearest)) # 1) < WARN_RANGE;
            if (_close && !_inside) then {[format ["LOA %1 - DO NOT CROSS", _name], NOTE_WARN, false] call _fnc_event};
            GVAR(inside) set [_mid, _close];
        };
        case "objective": {
            private _in = _now inPolygon _points;
            if (_in && !_inside) then {[format ["ON OBJ %1", _name], NOTE_COLOUR] call _fnc_event};
            GVAR(inside) set [_mid, _in];
        };
        case "rally_point";
        case "checkpoint": {
            private _in = (_now distance2D (_points # 0)) < NEAR_RANGE;
            if (_in && !_inside) then {[format [["PASSED CP %1", "AT RP %1"] select (_type isEqualTo "rally_point"), _name], NOTE_COLOUR] call _fnc_event};
            GVAR(inside) set [_mid, _in];
        };
    };
} forEach GVAR(measureList);
