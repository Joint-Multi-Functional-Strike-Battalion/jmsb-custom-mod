#include "script_component.hpp"
/*
 * Author: YonV
 * The player's colour for a building, picked on the strip or stepped by his
 * key (FUNC(markKey)): sent to the server (FUNC(markSet)). A pick past the
 * colours - CLEAR - takes the mark off; so does a forced MARK_CLEAR.
 *
 * Arguments:
 * 0: Index picked <NUMBER>
 * 1: Its word <STRING>
 * 2: [building, forced colour (optional)] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [2, "GREEN", [_house]] call jmfsb_ecoti_fnc_markPick
 *
 * Public: No
 */

params [["_index", 0, [0]], ["_word", "", [""]], ["_args", [], [[]]]];
_args params [["_building", objNull, [objNull]], ["_forced", nil, [0]]];

if (isNull _building) exitWith {};

private _colour = if (isNil "_forced") then {
    [MARK_CLEAR, _index] select (_index < count MARK_COLOURS)
} else {
    _forced
};

[_building, _colour, ""] remoteExecCall [QFUNC(markSet), SERVER_OWNER];
hintSilent format ["MARK %1", toUpper _word];
