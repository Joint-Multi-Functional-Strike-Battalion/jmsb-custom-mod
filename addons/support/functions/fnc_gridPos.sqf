#include "script_component.hpp"
/*
 * Author: YonV
 * A card's grid field as a position on this map (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 3). A grid field holds what the composer put
 * in it: a position from a map click, or a grid typed by hand - and a
 * MAP REFERENCE line may name a marker.
 *
 *   [x, y] or [x, y, z]     the position
 *   "034 127" ... "03412 12780"
 *                           a 6, 8 or 10 figure grid, spaces allowed, read on
 *                           this terrain's own grid (EFUNC(maptools,gridToPos),
 *                           the inverse of what the map prints)
 *   a marker name           where the marker is
 *
 * Anything else, a grid off this map, or a grid with maptools absent: none.
 *
 * Arguments:
 * 0: The field's value <ARRAY or STRING>
 *
 * Return Value:
 * Position [x, y, 0] ATL, [] for none <ARRAY>
 *
 * Example:
 * ["034 127"] call jmfsb_support_fnc_gridPos
 *
 * Public: Yes
 */

params [["_value", [], [[], ""]]];

if (_value isEqualType []) exitWith {
    private _east = _value param [0, ""];
    private _north = _value param [1, ""];
    if !(_east isEqualType 0 && _north isEqualType 0) exitWith {[]};
    [_east, _north, 0]
};

private _text = trim _value;
if (_text isEqualTo "") exitWith {[]};

// A marker by name first: a marker can be called "123456" and is then meant.
if ((markerShape _text) isNotEqualTo "") exitWith {
    (getMarkerPos _text) params ["_mx", "_my"];
    [_mx, _my, 0]
};

// Figures and spaces only, in one of the lengths a grid has.
private _codes = toArray _text;
private _figures = _codes select {_x >= CHAR_ZERO && _x <= CHAR_NINE};
if ((count _figures) + ({_x isEqualTo CHAR_SPACE} count _codes) isNotEqualTo count _codes) exitWith {[]};
if !((count _figures) in GRID_FIGURES) exitWith {[]};
if (isNil QEFUNC(maptools,gridToPos)) exitWith {
    WARNING_1("gridPos: '%1' - maptools is not loaded, a typed grid cannot be read",_text);
    []
};

[_text] call EFUNC(maptools,gridToPos)
