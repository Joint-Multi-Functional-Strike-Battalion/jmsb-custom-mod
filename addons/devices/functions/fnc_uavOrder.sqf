#include "script_component.hpp"
/*
 * Author: JMSB
 * An order to a drone's AI - the DRONES board's ORBIT, GO TO, RTB and LASE.
 * Waypoints and the designator are the crew's, and a UAV's crew is usually
 * the server's (a hand-thrown one its launcher's), so an order given anywhere
 * else is sent on to the machine that owns the drone's group
 * (CBA targetEvent jmfsb_devices_uavOrder, handled on every machine) and runs
 * there. What can be refused is refused on the caller first, from config.
 *
 *   "orbit"  [radius]             a LOITER circle where the drone is now
 *   "goto"   [position, radius]   a MOVE to the point at the drone's current
 *                                 height (UAV_ALT_MIN when on the ground),
 *                                 then a LOITER circle there
 *   "rtb"    [position, radius]   a MOVE to the home (FUNC(uavHome)); an
 *                                 airframe that can set down (UAV_LAND_KIND)
 *                                 lands there, any other loiters there
 *   "lase"   [on, target]         on: the designator's turret locked on the
 *                                 target (an object or a position AGL) and,
 *                                 after UAV_LASE_DELAY, the designator switched
 *                                 on; off: switched off and the turret freed.
 *                                 Refused when the airframe has no laser
 *                                 (FUNC(uavLaser)). The lased point is public on
 *                                 the drone as jmfsb_devices_uavLase.
 *
 * Who may give an order is the caller's business (FUNC(uavCan)); this only
 * carries it out.
 *
 * Arguments:
 * 0: Order <STRING>
 * 1: Drone <OBJECT>
 * 2: Order arguments <ARRAY> (optional, default [])
 *
 * Return Value:
 * [given <BOOL>, why not - "" when given <STRING>] <ARRAY>
 *
 * Example:
 * ["goto", _uav, [_pos, 300]] call jmfsb_devices_fnc_uavOrder
 * ["lase", _uav, [true, _pos]] call jmfsb_devices_fnc_uavOrder
 *
 * Public: Yes
 */

params [["_mode", "", [""]], ["_uav", objNull, [objNull]], ["_args", [], [[]]]];

if (!alive _uav) exitWith {[false, "That drone is gone."]};
if !(_mode in UAV_ORDERS) exitWith {
    WARNING_1("uavOrder: unknown order '%1'",_mode);
    [false, "Unknown order."]
};

private _laser = [_uav] call FUNC(uavLaser);
private _laseOn = _mode isEqualTo "lase" && {_args param [0, false]};
if (_laseOn && _laser isEqualTo []) exitWith {
    [false, "This airframe has no laser designator."]
};

if (_mode in ["goto", "rtb"] && count (_args param [0, []]) < 2) exitWith {[false, "No point to fly to."]};
if (_laseOn && (_args param [1, []]) in [[], objNull]) exitWith {
    [false, "Nothing to lase."]
};

private _grp = group _uav;
if (isNull _grp) exitWith {[false, "That drone has no crew."]};

// NOT OURS: on to the machine that owns the crew.
if (!local _grp) exitWith {
    private _owner = leader _grp;
    if (isNull _owner) then {_owner = _uav};
    [QGVAR(uavOrder), [_mode, _uav, _args], _owner] call CBA_fnc_targetEvent;
    [true, ""]
};

private _fnc_clear = {
    for "_i" from (count waypoints _grp) - 1 to 0 step -1 do {
        deleteWaypoint [_grp, _i];
    };
};

private _fnc_loiter = {
    params ["_pos", "_radius"];
    private _wp = _grp addWaypoint [_pos, 0];
    _wp setWaypointType "LOITER";
    _wp setWaypointLoiterType UAV_LOITER_TYPE;
    _wp setWaypointLoiterRadius _radius;
    _wp
};

// The height a MOVE flies at: the drone's own, held.
private _fnc_height = {
    private _alt = ((getPos _uav) select 2) max UAV_ALT_MIN;
    _uav flyInHeight _alt;
    _alt
};

switch (_mode) do {
    case "orbit": {
        _args params [["_radius", 0, [0]]];
        call _fnc_clear;
        private _wp = [getPosATL _uav, _radius] call _fnc_loiter;
        _grp setCurrentWaypoint _wp;
    };

    case "goto": {
        _args params [["_pos", [], [[]]], ["_radius", 0, [0]]];
        private _at = [_pos select 0, _pos select 1, call _fnc_height];
        call _fnc_clear;
        private _wp = _grp addWaypoint [_at, 0];
        _wp setWaypointType "MOVE";
        [_at, _radius] call _fnc_loiter;
        _grp setCurrentWaypoint _wp;
    };

    case "rtb": {
        _args params [["_pos", [], [[]]], ["_radius", 0, [0]]];
        private _at = [_pos select 0, _pos select 1, call _fnc_height];
        call _fnc_clear;
        private _wp = _grp addWaypoint [_at, 0];
        _wp setWaypointType "MOVE";
        if (_uav isKindOf UAV_LAND_KIND) then {
            _wp setWaypointStatements ["true", UAV_LAND_STATEMENT];
        } else {
            [_at, _radius] call _fnc_loiter;
        };
        _grp setCurrentWaypoint _wp;
    };

    case "lase": {
        _args params [["_on", false, [false]], ["_target", [], [[], objNull]]];
        if (_laser isEqualTo []) exitWith {};
        _laser params ["_weapon", "_turret"];

        if (!_on) exitWith {
            if (isLaserOn _uav) then {[_uav, _weapon, _turret] call BIS_fnc_fire};
            _uav lockCameraTo [objNull, _turret, false];
            _uav setVariable [QGVAR(uavLase), nil, true];
        };

        private _isObj = _target isEqualType objNull;
        private _aim = if (_isObj) then {_target} else {AGLToASL _target};
        private _point = if (_isObj) then {getPosATL _target} else {+_target};
        _uav lockCameraTo [_aim, _turret, false];
        _uav selectWeaponTurret [_weapon, _turret];
        _uav setVariable [QGVAR(uavLase), _point, true];

        [{
            params ["_uav", "_weapon", "_turret"];
            if (!alive _uav || {isLaserOn _uav}) exitWith {};
            if ((_uav getVariable [QGVAR(uavLase), []]) isEqualTo []) exitWith {};
            [_uav, _weapon, _turret] call BIS_fnc_fire;
        }, [_uav, _weapon, _turret], UAV_LASE_DELAY] call CBA_fnc_waitAndExecute;
    };
};

[true, ""]
