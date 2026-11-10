#include "script_component.hpp"
/*
 * Author: YonV
 * The phone's and side devices' status cell (jmfsb_devices' row; a provider
 * registered in XEH_preInit): the next waypoint's number, distance and
 * bearing while a route is walked - "3 420M 045°" (FUNC(legText): short, so
 * the strip keeps its size) - NO FIX in red when the GPS is denied, and a
 * dim -- when nothing is being walked.
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
if (_dist < 0) exitWith {[STATUS_ICON, format [CELL_FORMAT, _i + 1, LEG_NO_FIX], PM_STATE_ALERT]};

[STATUS_ICON, format [CELL_FORMAT, _i + 1, [_dist, _brg] call FUNC(legText)], PM_STATE_OK]
