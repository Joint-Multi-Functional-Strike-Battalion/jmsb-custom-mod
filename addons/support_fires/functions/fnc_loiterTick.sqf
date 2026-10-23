#include "script_component.hpp"
/*
 * Author: JMSB
 * One loitering munition's life, per frame handler on the server:
 *
 *   transit  - flying to the area; arriving puts it on station, an orbit
 *              over the point, with the loiter clock running
 *   station  - every LM_SCAN seconds it looks for the best target its strike
 *              rules allow (FUNC(pickTarget)); out of time, it self-destructs
 *   dive     - flown straight at the target's aim point at dive speed, the
 *              warhead set off on arrival; a target that dies first sends it
 *              back to the hunt
 *
 * A munition killed on the way is lost; a recall (FUNC(abort)) sets every
 * one off where it is.
 *
 * Arguments:
 * 0: [uav, logic, centre, radius, token, enemy, rule, warhead, mode, until, nextScan, prey] <ARRAY>
 * 1: Handler id <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * (CBA per frame handler, see FUNC(loiterOne))
 *
 * Public: No
 */

params ["_args", "_handle"];
_args params ["_uav", "_logic", "_center", "_radius", "_token", "_enemy", "_rule", "_warhead", "_mode", "_until", "_nextScan", "_prey"];

private _end = {
    params ["_said"];
    [_handle] call CBA_fnc_removePerFrameHandler;
    private _claimed = _logic getVariable [QGVAR(claimed), []];
    private _i = _claimed find _prey;
    if (_i > -1) then {_claimed deleteAt _i};
    [_logic, _token, _said] call FUNC(sortieDone);
};

if (!alive _uav) exitWith {["munition lost"] call _end};

if (_logic getVariable [QGVAR(abort), false]) exitWith {
    [_uav, _warhead] call FUNC(detonate);
    ["munition self-destructed"] call _end;
};

private _now = CBA_missionTime;

switch (_mode) do {
    case "transit": {
        if ((_uav distance2D _center) <= (LM_STATION_RING max _radius)) then {
            private _grp = group driver _uav;
            for "_i" from (count waypoints _grp - 1) to 0 step -1 do {
                deleteWaypoint [_grp, _i];
            };
            private _wp = _grp addWaypoint [_center, 0];
            _wp setWaypointType "LOITER";
            _wp setWaypointLoiterType "CIRCLE_L";
            _wp setWaypointLoiterRadius ((_radius * LM_ORBIT_SHARE) max LM_ORBIT_MIN);

            _args set [8, "station"];
            _args set [9, _now + (_logic getVariable [QGVAR(loiterTime), 0])];
            _args set [10, _now];
            if ((_logic getVariable [QGVAR(status), ""]) isNotEqualTo STATUS_STATION) then {
                _logic setVariable [QGVAR(status), STATUS_STATION, true];
                [QGVAR(say), [_logic, format ["on station over %1, hunting", mapGridPosition _center], "high"]] call CBA_fnc_globalEvent;
            };
        } else {
            if (_now > _until) then {
                [_uav, _warhead] call FUNC(detonate);
                ["munition never reached the area - self-destructed"] call _end;
            };
        };
    };
    case "station": {
        if (_now > _until) exitWith {
            [_uav, _warhead] call FUNC(detonate);
            ["loiter time up, nothing found - self-destructed"] call _end;
        };
        if (_now >= _nextScan) then {
            _args set [10, _now + LM_SCAN];
            private _claimed = _logic getVariable [QGVAR(claimed), []];
            private _found = [_uav, _center, _radius, _rule, _enemy, _claimed] call FUNC(pickTarget);
            if (!isNull _found) then {
                _claimed pushBack _found;
                _logic setVariable [QGVAR(claimed), _claimed];
                _args set [11, _found];
                _args set [8, "dive"];
                (driver _uav) disableAI "ALL";
                [QGVAR(say), [_logic, format ["target acquired, %1 - diving", getText (configOf _found >> "displayName")], "normal"]] call CBA_fnc_globalEvent;
            };
        };
    };
    case "dive": {
        if (!alive _prey) exitWith {
            private _claimed = _logic getVariable [QGVAR(claimed), []];
            private _i = _claimed find _prey;
            if (_i > -1) then {_claimed deleteAt _i};
            _args set [11, objNull];
            _args set [8, "station"];
            (driver _uav) enableAI "ALL";
        };
        private _aim = aimPos _prey;
        private _p = getPosASL _uav;
        // Fuzed on what it will cover before the next tick, not a fixed ring:
        // at dive speed a tick is several metres, and a tick that misses the
        // ring lets the airframe hit the hull and break up with no warhead.
        private _reach = LM_FUZE + (vectorMagnitude velocity _uav) * LM_TICK * FUZE_LOOKAHEAD_TICKS;
        if ((_p vectorDistance _aim) <= _reach || {((getPosATL _uav) select 2) < 1}) exitWith {
            [_uav, _warhead, _aim] call FUNC(detonate);
            ["impact"] call _end;
        };
        private _dir = _p vectorFromTo _aim;
        _uav setVectorDir _dir;
        _uav setVelocity (_dir vectorMultiply ((vectorMagnitude velocity _uav) max LM_DIVE_SPEED));
    };
    default {};
};
