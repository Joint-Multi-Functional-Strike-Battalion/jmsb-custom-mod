#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether an asset can put its fires on a point - the one range answer the
 * request (FUNC(task)), the server (FUNC(fireMission)) and the coordination
 * search (FUNC(partners)) all use, so none of them can disagree. The limits
 * are FUNC(gunRanges); a battery's arc is also solved (FUNC(ballistics)) as
 * the last word.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position <ARRAY>
 *
 * Return Value:
 * Why not, "" when it can <STRING>
 *
 * Example:
 * [_logic, [1000, 2000, 0]] call jmfsb_support_fires_fnc_inRange
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_target", [], [[]]]];

if (isNull _logic || {_target isEqualTo []}) exitWith {"no target point"};

private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _dist = _origin distance2D _target;
([_logic] call FUNC(gunRanges)) params ["_min", "_max"];

if (_dist < _min) exitWith {format ["target inside minimum range (%1)", [_min] call FUNC(fmtDist)]};
if (_dist > _max) exitWith {format ["target beyond maximum range (%1)", [_max] call FUNC(fmtDist)]};

if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY) exitWith {""};

private _ball = [_dist, _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV], _logic getVariable [QGVAR(highAngle), true]] call FUNC(ballistics);
["no firing solution for that point", ""] select (_ball isNotEqualTo [])
