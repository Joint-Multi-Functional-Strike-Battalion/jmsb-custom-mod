#include "script_component.hpp"
/*
 * Author: JMSB
 * One measured leg: the line, and its distance and bearing at the midpoint.
 * The ruler, every route leg and every rubber band are this - one look for a
 * measurement wherever it lands.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: From, world position <ARRAY>
 * 2: To, world position <ARRAY>
 * 3: Colour <ARRAY>
 * 4: Label size <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, _from, _to, _accent, 0.045] call jmfsb_maptools_fnc_drawLeg
 *
 * Public: No
 */

params ["_map", "_from", "_to", "_color", "_size"];

_map drawLine [_from, _to, _color];

private _mid = [((_from # 0) + (_to # 0)) / 2, ((_from # 1) + (_to # 1)) / 2];

[
    _map, _mid,
    format ["%1  %2", [_from distance2D _to] call FUNC(distanceText), [_from getDir _to] call FUNC(bearingText)],
    _color, _size, "center"
] call FUNC(label);
