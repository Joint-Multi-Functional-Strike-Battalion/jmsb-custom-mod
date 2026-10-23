#include "script_component.hpp"
/*
 * Author: JMSB
 * Keeps the cursor's world position for the readouts that follow it - GRID,
 * a ruler's rubber band, the protractor's free arm, the next route leg. The
 * cursor leaving the map clears it, so nothing is drawn to where it last was.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: Screen x <NUMBER>
 * 2: Screen y <NUMBER>
 * 3: Mouse over the control <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, 0.5, 0.5, true] call jmfsb_maptools_fnc_mouseMove
 *
 * Public: No
 */

params ["_map", "_sx", "_sy", ["_over", true]];

GVAR(cursor) = if (_over) then {_map ctrlMapScreenToWorld [_sx, _sy]} else {[]};
