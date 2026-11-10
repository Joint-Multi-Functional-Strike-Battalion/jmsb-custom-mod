#include "script_component.hpp"
/*
 * Author: YonV
 * Orders a helicopter to a point the way Simplex Support Services does it
 * (2026-11-05 - flight control modelled on how Simplex pilots a helicopter;
 * no code of it used): no group waypoint. The airframe itself is told to move
 * (doMove), and FUNC(heliOrderTick) tells it again every HELI_ORDER_TICK s for
 * as long as the AI reports itself idle short of the point. A LOITER is the
 * same order stepped round a ring. The user's two runs of 2026-11-05 (RPT
 * 16:23, 17:13): the UH-80 given one group MOVE waypoint hovered over its
 * module with no waypoint on it.
 *
 * A flight control holding the airframe (FUNC(heliTake)) lets go first; a
 * pilot left without a path after a landing gets it back; the engine is
 * started, any landing order cancelled, the crew's speed mode set. Every
 * caller of FUNC(moveTo) reaches this for a helicopter.
 *
 * Arguments:
 * 0: The helicopter <OBJECT>
 * 1: The point, [x, y] or [x, y, z] <ARRAY>
 * 2: Speed mode - "LIMITED", "NORMAL", "FULL" <STRING> (optional, default "NORMAL")
 * 3: "MOVE" to the point, "LOITER" round it <STRING> (optional, default "MOVE")
 * 4: The ring a LOITER flies, m - RADIUS_MIN when none <NUMBER> (optional, default 0)
 *
 * Return Value:
 * Ordered <BOOL>
 *
 * Example:
 * [_veh, _pos, "LIMITED", "LOITER", 200] call jmfsb_support_air_fnc_heliOrder
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_pos", [], [[]]], ["_speed", "NORMAL", [""]], ["_type", "MOVE", [""]], ["_radius", 0, [0]]];

if (!alive _veh || count _pos < 2) exitWith {false};
private _pilot = driver _veh;
if (isNull _pilot) exitWith {false};
if (_radius <= 0) then {_radius = RADIUS_MIN};

if (count (_veh getVariable [QGVAR(flight), createHashMap]) > 0) then {
    [_veh, "a new order"] call FUNC(heliRelease);
};

_veh land "NONE";
_veh engineOn true;
_pilot enableAI "PATH";
// A waypoint left on the group - a helicopter is given none any more - would
// pull against the order.
[group _pilot] call CBA_fnc_clearWaypoints;
(group _pilot) setSpeedMode _speed;

_veh setVariable [QGVAR(order), createHashMapFromArray [
    ["at", [_pos select 0, _pos select 1, 0]],
    ["type", _type],
    ["radius", _radius],
    ["bearing", -1],
    ["issued", -1],
    ["reissues", 0],
    ["best", HELI_FAR],
    ["logged", -HELI_FAR]
]];

// The watch, one per airframe; the first order goes now, not a tick later.
private _handle = _veh getVariable [QGVAR(orderPfh), -1];
if (_handle < 0) then {
    _handle = [FUNC(heliOrderTick), HELI_ORDER_TICK, [_veh]] call CBA_fnc_addPerFrameHandler;
    _veh setVariable [QGVAR(orderPfh), _handle];
};
[[_veh], _handle] call FUNC(heliOrderTick);
// No rise to slow down while the AI flies it (2026-11-08, FUNC(heliNoRise)).
if ((_veh getVariable [QGVAR(noRisePfh), -1]) < 0) then {
    _veh setVariable [QGVAR(noRisePfh), [FUNC(heliNoRise), 0, [_veh]] call CBA_fnc_addPerFrameHandler];
};
true
