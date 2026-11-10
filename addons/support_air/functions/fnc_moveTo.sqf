#include "script_component.hpp"
/*
 * Author: YonV
 * Sends an aircraft to one point and nowhere else. One RPT line says where to
 * (2026-11-05).
 *
 * A HELICOPTER is ordered Simplex's way (2026-11-05, FUNC(heliOrder)): the
 * airframe itself is told to move, and told again whenever it is idle short
 * of the point - no group waypoint, which the user's two runs showed it
 * hovering without. A LOITER is the ring flown point by point. A flight
 * control holding it (FUNC(heliTake)) lets go.
 *
 * A FIXED-WING AIRCRAFT flies a group waypoint as before: every waypoint it
 * had is dropped, one replaces them, any landing order is cancelled.
 *
 * A VTOL (2026-11-08) is the plane beyond VTOL_PLANE_RANGE of the point and
 * on a LOITER, the helicopter inside it - handed over on the way in.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Where to, ATL <ARRAY>
 * 2: Speed - "LIMITED", "NORMAL", "FULL" <STRING> (optional, default "NORMAL")
 * 3: "MOVE" or "LOITER" <STRING> (optional, default "MOVE")
 * 4: Loiter radius, m <NUMBER> (optional, default 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, _pos, "FULL"] call jmfsb_support_air_fnc_moveTo
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_pos", [], [[]]], ["_speed", "NORMAL", [""]], ["_type", "MOVE", [""]], ["_radius", 0, [0]]];

if (!alive _veh || {_pos isEqualTo []}) exitWith {};

private _grp = group driver _veh;
if (isNull _grp) exitWith {};

// Every order in the RPT (2026-11-05: RAVEN hovered and the RPT could not say
// where it had been sent).
INFO_5("moveTo: '%1' %2 %3 to %4, %5 m",typeOf _veh,_type,_speed,mapGridPosition _pos,round (_veh distance2D _pos));

// A VTOL IS A HELICOPTER ONLY NEAR ITS POINT (user, 2026-11-08: "helo only in
// landing and take off, needs to use flight mode over distances over 1k"):
// beyond VTOL_PLANE_RANGE, or on a LOITER, it flies the plane's waypoint, and
// a MOVE is handed to the helicopter order once inside the range. Every order
// to a VTOL numbers its leg, so a hand-over a newer order replaced is dropped.
private _vtol = _veh isKindOf "VTOL_Base_F";
private _plane = _vtol && {_type isEqualTo "LOITER" || {_veh distance2D _pos > VTOL_PLANE_RANGE}};
private _leg = (_veh getVariable [QGVAR(vtolLeg), 0]) + 1;
if (_vtol) then {_veh setVariable [QGVAR(vtolLeg), _leg]};

// CLIMB OUT AS A HELICOPTER FIRST (user, 2026-11-08: "crashed in to a
// mountain on rtb" - switched to the plane in an 11 m hover, it flew into the
// hill): a VTOL lower than VTOL_PLANE_MIN_ALT m over the ground climbs out on
// the helicopter order toward the point, and the plane leg is ordered once it
// is that high (or VTOL_CLIMB_S s have passed).
if (_plane && {((getPosATL _veh) select 2) < VTOL_PLANE_MIN_ALT}) exitWith {
    [_veh, _pos, _speed, "MOVE", 0] call FUNC(heliOrder);
    [{
        params ["_veh", "_pos", "_leg"];
        !alive _veh || {(_veh getVariable [QGVAR(vtolLeg), 0]) isNotEqualTo _leg} || {((getPosATL _veh) select 2) >= VTOL_PLANE_MIN_ALT}
    }, {
        params ["_veh", "_pos", "_leg", "_speed", "_type", "_radius"];
        if (!alive _veh || {(_veh getVariable [QGVAR(vtolLeg), 0]) isNotEqualTo _leg}) exitWith {};
        [_veh, _pos, _speed, _type, _radius] call FUNC(moveTo);
    }, [_veh, _pos, _leg, _speed, _type, _radius], VTOL_CLIMB_S, {
        // never that high: it stays on the helicopter order all the way
        params ["_veh"];
        WARNING_2("moveTo: '%1' still under %2 m after the climb-out - flying on as a helicopter",typeOf _veh,VTOL_PLANE_MIN_ALT);
    }] call CBA_fnc_waitUntilAndExecute;
};

if ([_veh] call EFUNC(support,isRotary) && !_plane) exitWith {
    [_veh, _pos, _speed, _type, _radius] call FUNC(heliOrder);
};

if (_plane) then {
    // off the helicopter's order and flight control, onto the waypoint
    if (count (_veh getVariable [QGVAR(flight), createHashMap]) > 0) then {[_veh, "a plane leg"] call FUNC(heliRelease)};
    _veh setVariable [QGVAR(order), nil];
    if (_type isEqualTo "LOITER") exitWith {};
    [{
        params ["_veh", "_pos", "_leg"];
        !alive _veh || {(_veh getVariable [QGVAR(vtolLeg), 0]) isNotEqualTo _leg} || {_veh distance2D _pos <= VTOL_PLANE_RANGE}
    }, {
        params ["_veh", "_pos", "_leg", "_speed", "_type", "_radius"];
        if (!alive _veh || {(_veh getVariable [QGVAR(vtolLeg), 0]) isNotEqualTo _leg}) exitWith {};
        // the flight control already has it (a landing ordered on the way in)
        if (count (_veh getVariable [QGVAR(flight), createHashMap]) > 0) exitWith {};
        [_veh, _pos, _speed, _type, _radius] call FUNC(moveTo);
    }, [_veh, _pos, _leg, _speed, _type, _radius]] call CBA_fnc_waitUntilAndExecute;
};

_veh land "NONE";
[_grp] call CBA_fnc_clearWaypoints;

private _wp = _grp addWaypoint [_pos, 0];
_wp setWaypointType _type;
_wp setWaypointSpeed _speed;
if (_radius > 0) then {_wp setWaypointLoiterRadius _radius};
_grp setCurrentWaypoint _wp;
