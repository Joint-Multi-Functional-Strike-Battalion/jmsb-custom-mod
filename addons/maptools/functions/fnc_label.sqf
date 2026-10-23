#include "script_component.hpp"
/*
 * Author: JMSB
 * A line of text on the map at a world position - drawIcon with nothing to
 * draw but the text, shadowed so it reads over contour lines and forest.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: World position <ARRAY>
 * 2: Text <STRING>
 * 3: Colour <ARRAY>
 * 4: Size <NUMBER>
 * 5: Alignment relative to the position <STRING> (optional, default "right")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_map, _pos, "TOTAL 1.20 KM", _accent, 0.045] call jmfsb_maptools_fnc_label
 *
 * Public: No
 */

params ["_map", "_pos", "_text", "_color", "_size", ["_align", "right", [""]]];

_map drawIcon [ICON_NONE, _color, _pos, ICON_SIZE_LABEL, ICON_SIZE_LABEL, 0, _text, LABEL_SHADOW, _size, LABEL_FONT, _align];
