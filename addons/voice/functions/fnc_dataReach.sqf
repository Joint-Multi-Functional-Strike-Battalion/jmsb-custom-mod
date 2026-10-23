#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: whether one player reaches another on DATA - any node of his has a
 * path to any node of the other's (rf_reach). A call needs it.
 *
 * Arguments:
 * 0: From <OBJECT>
 * 1: To <OBJECT>
 *
 * Return Value:
 * Reachable <BOOL>
 *
 * Example:
 * [_a, _b] call jmfsb_voice_fnc_dataReach
 *
 * Public: No
 */

params [["_a", objNull, [objNull]], ["_b", objNull, [objNull]]];

if (isNull _a || isNull _b) exitWith {false};
private _theirs = [_b] call FUNC(nodeIds);
private _found = false;
{
    private _reach = [_x, NET_DATA] call EFUNC(rf,reach);
    if ((_theirs findIf {_x in _reach}) >= 0) exitWith {_found = true};
} forEach ([_a] call FUNC(nodeIds));
_found
