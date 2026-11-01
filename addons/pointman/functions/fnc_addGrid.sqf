#include "script_component.hpp"
/*
 * Author: JMSB
 * Adds a waypoint from a typed grid - 6, 8 or 10 figures, spaces allowed
 * (jmfsb_maptools_fnc_gridToPos). A grid that is not on this map is refused
 * and said so.
 *
 * Arguments:
 * 0: Grid reference <STRING>
 *
 * Return Value:
 * Added <BOOL>
 *
 * Example:
 * ["034 127"] call jmfsb_pointman_fnc_addGrid
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

private _grid = trim _text;
if (_grid isEqualTo "") exitWith {false};

private _pos = [_grid] call EFUNC(maptools,gridToPos);
if (_pos isEqualTo []) exitWith {
    [format ["'%1' is not a grid on this map: 6, 8 or 10 figures.", _grid], "high"] call FUNC(say);
    false
};

private _i = [_pos, _grid] call FUNC(add);
if (_i < 0) exitWith {false};
[format ["WP %1 added at %2.", _i + 1, _grid]] call FUNC(say);
true
