#include "script_component.hpp"
/*
 * Author: YonV
 * The watch on a helicopter's order (FUNC(heliOrder)), every HELI_ORDER_TICK
 * s - Simplex's way: the AI is told the point again whenever it reports
 * itself idle short of it.
 *
 *   MOVE     done inside HELI_ORDER_RING m of the point, airborne and idle -
 *            the AI then hovers there on its own. Idle short of it: ordered
 *            again. On the ground inside HELI_TAKEOFF_PAST m of it, too near
 *            for the AI to lift off for: ordered that far past it first.
 *            HELI_STUCK_REISSUES orders in a row without the distance
 *            shrinking HELI_PROGRESS m - the AI refusing nap of the earth
 *            over what is under it - climb it HELI_STUCK_CLIMB m; the next
 *            leg's plan sets the height back
 *   LOITER   the ring HELI_ORBIT_STEP deg at a time from the point of it
 *            nearest the airframe, the next point ordered once inside
 *            HELI_ORBIT_NEXT of the radius or when the AI is idle. Never done
 *
 * An order given again is said in the RPT - the first time, then at most
 * every HELI_ORDER_LOG_S s - with what the airframe is doing (2026-11-05: the
 * RPT could not say why RAVEN hovered). The watch ends with the order: done,
 * dropped (FUNC(heliTake) holds the airframe), the airframe gone or no longer
 * the server's.
 *
 * Arguments:
 * 0: [helicopter] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(heliOrderTick), 2, [_veh]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_veh"];

private _order = _veh getVariable [QGVAR(order), createHashMap];
if (!alive _veh || count _order isEqualTo 0 || !local _veh || isNull driver _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    _veh setVariable [QGVAR(orderPfh), -1];
    _veh setVariable [QGVAR(order), nil];
};
// The flight control has it: the order is over when it lets go.
if (count (_veh getVariable [QGVAR(flight), createHashMap]) > 0) exitWith {};

private _at = _order get "at";
private _issued = _order get "issued";
private _ready = unitReady _veh;
private _d = _veh distance2D _at;
private _move = (_order get "type") isNotEqualTo "LOITER";

// DONE: there, airborne and idle - the AI hovers on its own now.
if (_move && _issued >= 0 && _ready && _d < HELI_ORDER_RING && {!isTouchingGround _veh}) exitWith {
    _veh setVariable [QGVAR(order), nil];
    [_handle] call CBA_fnc_removePerFrameHandler;
    _veh setVariable [QGVAR(orderPfh), -1];
};

private _go = false;
private _point = _at;
if (_move) then {
    if (_d < (_order get "best") - HELI_PROGRESS) then {
        _order set ["best", _d];
        _order set ["bestAt", CBA_missionTime];
        _order set ["reissues", 0];
    };
    _go = _issued < 0 || _ready;
    // BUSY AND GOING NOWHERE (user, 2026-11-08: the Ghost Hawk "never moved",
    // the Chinook went back and forth - and the RPT said nothing, since only
    // an idle AI was ordered again): no HELI_PROGRESS m closer for
    // HELI_BUSY_STUCK_S s while the AI says it is busy - ordered again, and
    // said, like an idle one.
    if (!_go && _issued >= 0 && {CBA_missionTime - (_order getOrDefault ["bestAt", _issued]) > HELI_BUSY_STUCK_S}) then {
        _order set ["bestAt", CBA_missionTime];
        _order set ["logged", -HELI_FAR];
        _go = true;
    };
    if (_go && {isTouchingGround _veh} && _d < HELI_TAKEOFF_PAST) then {
        _point = _veh getPos [HELI_TAKEOFF_PAST, _veh getDir _at];
    };
} else {
    private _radius = _order get "radius";
    private _bearing = _order get "bearing";
    if (_bearing < 0) then {
        _bearing = _at getDir _veh;
        _go = true;
    } else {
        if (_ready || _veh distance2D (_at getPos [_radius, _bearing]) < _radius * HELI_ORBIT_NEXT) then {
            _bearing = (_bearing + HELI_ORBIT_STEP) mod HELI_FULL_TURN;
            _go = true;
        };
    };
    _order set ["bearing", _bearing];
    _point = _at getPos [_radius, _bearing];
};
if (!_go) exitWith {};

// ORDERED AGAIN: counted, climbed when stuck, said.
if (_issued >= 0) then {
    private _n = (_order get "reissues") + 1;
    _order set ["reissues", _n];
    private _climbed = "";
    if (_move && _n >= HELI_STUCK_REISSUES) then {
        _order set ["reissues", 0];
        private _up = ((getPosATL _veh) select 2) + HELI_STUCK_CLIMB;
        [_veh, _up] call EFUNC(support,flyAt);
        _climbed = format [" - climbing to %1 m", round _up];
    };
    // A LOITER's next ring point is by design, not said.
    if (_move && (_climbed isNotEqualTo "" || CBA_missionTime - (_order get "logged") >= HELI_ORDER_LOG_S)) then {
        _order set ["logged", CBA_missionTime];
        private _state = format [
            "%1 km/h, %2 m up, engine %3, %4, %5, fuel %6, AI %7, crew %8",
            round speed _veh,
            round ((getPosATL _veh) select 2),
            ["off", "on"] select (isEngineOn _veh),
            behaviour driver _veh,
            ["in the air", "on the ground"] select (isTouchingGround _veh),
            fuel _veh toFixed 2,
            ["busy", "idle"] select _ready,
            count crew _veh
        ];
        INFO_5("heliOrderTick: '%1' %2 m short of %3 - ordered again (%4)%5",typeOf _veh,round _d,mapGridPosition _at,_state,_climbed);
    };
};

_veh doMove _point;
_order set ["issued", CBA_missionTime];
