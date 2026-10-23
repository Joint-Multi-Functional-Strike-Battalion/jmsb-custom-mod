#include "script_component.hpp"
/*
 * Author: JMSB
 * Drops a marker at a point, labelled with its ten-digit grid and the time.
 *
 * THE GAME'S OWN MARKER PATH, not a new one. It is made through
 * EFUNC(common,createPlayerMarker), so it is an ordinary player marker - named
 * the way the engine names them, owned by this player, on the group channel -
 * which the vanilla map deletes and edits like any other, and which TAC//MSG's
 * MAP MARKER list (EFUNC(tacpad,markerGrids)) offers like any other.
 *
 * Kept local unless the player shares marks (QGVAR(markShare)). Shared, the
 * last setter is the global one, which is what puts a local marker out on its
 * channel - the group's, so the group sees it and nobody else does.
 *
 * Arguments:
 * 0: World position <ARRAY>
 *
 * Return Value:
 * The marker, "" when none was made <STRING>
 *
 * Example:
 * [getPosATL player] call jmfsb_maptools_fnc_mark
 *
 * Public: Yes
 */

params [["_pos", [], [[]]]];

if (count _pos < 2) exitWith {""};

private _marker = [[_pos # 0, _pos # 1, 0], MARK_CHANNEL] call EFUNC(common,createPlayerMarker);
if (_marker isEqualTo "") exitWith {""};

private _text = format ["%1 %2", [_pos] call FUNC(gridText), [dayTime, MARK_TIME_FORMAT] call BIS_fnc_timeToString];

_marker setMarkerShapeLocal "ICON";
_marker setMarkerTypeLocal MARK_TYPE;

if (GVAR(markShare)) then {
    _marker setMarkerText _text;
} else {
    _marker setMarkerTextLocal _text;
    GVAR(marks) pushBack _marker;
};

_marker
