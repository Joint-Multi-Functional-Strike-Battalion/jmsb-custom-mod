#include "script_component.hpp"
/*
 * Author: JMSB
 * The phone's status cell (jmfsb_devices' row; a provider registered in
 * XEH_preInit): the next waypoint's number, distance and bearing while a
 * route is walked - "3 420 M 045" - NO FIX in red when the GPS is denied,
 * and a dim -- when nothing is being walked.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [icon word, value, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_pointman_fnc_cell
 *
 * Public: No
 */

([] call FUNC(state)) params ["_nav", "_i", "", "", "_dist", "_brg"];

if (!_nav) exitWith {[STATUS_ICON, "--", PM_STATE_OFF]};
if (_dist < 0) exitWith {[STATUS_ICON, format ["%1 NO FIX", _i + 1], PM_STATE_ALERT]};

[STATUS_ICON, format ["%1 %2 %3", _i + 1, [_dist] call EFUNC(maptools,distanceText), [_brg] call EFUNC(maptools,bearingText)], PM_STATE_OK]
