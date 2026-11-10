#include "script_component.hpp"
/*
 * Author: YonV
 * A CAS aircraft has nothing left to strike with: Winchester, home
 * (FUNC(casTick), FUNC(casRun), FUNC(casJob) - 2026-11-05, one place for the
 * three). Said on the side's rail, every thread it answers CLOSED WINCHESTER
 * (doc 1.1), and the sortie turns for home on its next tick (FUNC(homeTick)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The sortie's state <HASHMAP>
 * 2: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _st, _requester] call jmfsb_support_air_fnc_casWinchester
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_requester", objNull, [objNull]]];

if (isNull _logic) exitWith {};

[_logic, "is Winchester, returning to base", "normal", _requester] call FUNC(say);
_logic setVariable [QGVAR(onStation), false];
[_logic, "CLOSED", OFF_WINCHESTER] call FUNC(threadState);
_st set ["phase", "home"];
