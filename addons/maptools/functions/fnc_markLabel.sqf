#include "script_component.hpp"
/*
 * Author: YonV
 * MARK's label for a point: its ten-digit grid and the time. What a MARK
 * marker has always said, and now the text MARK's marker card opens with.
 *
 * Arguments:
 * 0: World position <ARRAY>
 *
 * Return Value:
 * The label <STRING>
 *
 * Example:
 * [getPosATL player] call jmfsb_maptools_fnc_markLabel
 *
 * Public: No
 */

params [["_pos", [], [[]]]];

format ["%1 %2", [_pos] call FUNC(gridText), [dayTime, MARK_TIME_FORMAT] call BIS_fnc_timeToString]
