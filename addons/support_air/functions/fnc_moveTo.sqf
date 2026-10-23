#include "script_component.hpp"
/*
 * Author: JMSB
 * Sends an aircraft's crew to one point and nowhere else: every waypoint it
 * had is dropped, one MOVE replaces them, any landing order is cancelled.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Where to, ATL <ARRAY>
 * 2: Waypoint speed - "LIMITED", "NORMAL", "FULL" <STRING> (optional, default "NORMAL")
 * 3: Waypoint type <STRING> (optional, default "MOVE")
 * 4: Loiter radius for a LOITER waypoint, m <NUMBER> (optional, default 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, _pos, "FULL"] call jmfsb_support_air_fnc_moveTo
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_pos", [], [[]]], ["_speed", "NORMAL", [""]], ["_type", "MOVE", [""]], ["_radius", 0, [0]]];

if (!alive _veh || {_pos isEqualTo []}) exitWith {};

private _grp = group driver _veh;
if (isNull _grp) exitWith {};

_veh land "NONE";
[_grp] call CBA_fnc_clearWaypoints;

private _wp = _grp addWaypoint [_pos, 0];
_wp setWaypointType _type;
_wp setWaypointSpeed _speed;
if (_radius > 0) then {_wp setWaypointLoiterRadius _radius};
_grp setCurrentWaypoint _wp;
