#include "script_component.hpp"
/*
 * Author: YonV
 * One marked building's box for this frame (user, 2026-11-06): its real
 * bounding box on the screen in the mark's colour, its label and range under
 * it. No line-of-sight test - a mark is told, not seen; it fades with range as
 * a vehicle's box does, out to MARK_RANGE.
 *
 * Arguments:
 * 0: [building, rgb, label] <ARRAY>
 * 1: View - [camPos, camFwd, camRight, camUp, window] <ARRAY>
 *
 * Return Value:
 * [rect, colour, [label text, lines]], [] when not drawn <ARRAY>
 *
 * Example:
 * [[_house, [1, 0, 0], "OBJ"], _view] call jmfsb_ecoti_fnc_buildingBox
 *
 * Public: No
 */

params ["_mark", "_view"];
_mark params ["_building", "_rgb", "_label"];
_view params ["_camPos"];

if (isNull _building) exitWith {[]};

(boundingBoxReal _building) params ["_min", "_max"];
_min params ["_x1", "_y1", "_z1"];
_max params ["_x2", "_y2", "_z2"];

private _corners = [
    [_x1, _y1, _z1], [_x2, _y1, _z1], [_x1, _y2, _z1], [_x2, _y2, _z1],
    [_x1, _y1, _z2], [_x2, _y1, _z2], [_x1, _y2, _z2], [_x2, _y2, _z2]
] apply {_building modelToWorldVisual _x};

private _rect = [_corners, 0, _view] call FUNC(boxRect);
if (_rect isEqualTo []) exitWith {[]};

private _dist = _camPos distance (_building modelToWorldVisual ORIGIN);
private _alpha = linearConversion [GVAR(nearDistance), MARK_RANGE, _dist, 1, FAR_ALPHA_MIN, true];

private _text = if (GVAR(labels)) then {
    [format ["<t align='center' color='%1'>%2%3%4</t>", _rgb call BIS_fnc_colorRGBtoHTML, _label, LABEL_SEPARATOR, [_dist] call FUNC(rangeText)], 1]
} else {
    ["", 0]
};

[_rect, _rgb + [_alpha], _text]
