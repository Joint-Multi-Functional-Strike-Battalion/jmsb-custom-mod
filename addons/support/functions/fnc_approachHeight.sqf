#include "script_component.hpp"
/*
 * Author: YonV
 * The height to fly at this far from a task point whose task has a height of
 * its own - a drop, a jump, a static line (user, 2026-11-01). Far out it is the
 * tactical transit height (FUNC(flightHeight)); from APPROACH_SLOPE m per m of
 * difference out (no closer than APPROACH_MIN) it moves on a straight slope to
 * the task's height, reached over the point. A helicopter climbs late out of
 * nap of the earth; a fixed-wing comes down from its transit altitude.
 *
 * Asked every tick of the inbound leg; the AI follows the change.
 *
 * Arguments:
 * 0: The aircraft, or its class <OBJECT or STRING>
 * 1: The task's own height, m above the terrain <NUMBER>
 * 2: Distance to the task point, m (2D) <NUMBER>
 *
 * Return Value:
 * Height above the terrain, m <NUMBER>
 *
 * Example:
 * [_veh, 250, _veh distance2D _dz] call jmfsb_support_fnc_approachHeight
 *
 * Public: Yes
 */

params [["_what", objNull, [objNull, ""]], ["_task", 0, [0]], ["_distance", 0, [0]]];

private _cruise = [_what, PHASE_TRANSIT] call FUNC(flightHeight);
private _ring = (abs (_cruise - _task) * APPROACH_SLOPE) max APPROACH_MIN;

if (_distance >= _ring) exitWith {_cruise};

_task + (_cruise - _task) * (_distance / _ring)
