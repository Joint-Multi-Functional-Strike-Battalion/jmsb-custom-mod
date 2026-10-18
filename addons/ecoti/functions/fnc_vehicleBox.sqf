#include "script_component.hpp"
/*
 * Author: JMSB
 * One vehicle's or animal's box for this frame: round its bounding box
 * (FUNC(boxRect)), in the colour of whoever crews it (FUNC(targetColour) -
 * yellow when nobody does, faded with range), with its AiTR label.
 *
 * Arguments:
 * 0: Vehicle or animal <OBJECT>
 * 1: View - [camPos, camFwd, camRight, camUp, window] <ARRAY>
 *
 * Return Value:
 * [rect, colour RGBA, [label, lines]] or [] when it is not drawn <ARRAY>
 *
 * Example:
 * [_vehicle, _view] call jmfsb_ecoti_fnc_vehicleBox
 *
 * Public: No
 */

params ["_vehicle", "_view"];
_view params ["_camPos"];

if !(_vehicle getVariable [QGVAR(seen), false]) exitWith {[]};

(boundingBoxReal _vehicle) params ["_min", "_max"];
_min params ["_x1", "_y1", "_z1"];
_max params ["_x2", "_y2", "_z2"];

private _corners = [
    [_x1, _y1, _z1], [_x2, _y1, _z1], [_x1, _y2, _z1], [_x2, _y2, _z1],
    [_x1, _y1, _z2], [_x2, _y1, _z2], [_x1, _y2, _z2], [_x2, _y2, _z2]
] apply {_vehicle modelToWorldVisual _x};

private _rect = [_corners, 0, _view] call FUNC(boxRect);
if (_rect isEqualTo []) exitWith {[]};

private _dist = _camPos distance (_vehicle modelToWorldVisual ORIGIN);
private _alpha = linearConversion [GVAR(nearDistance), GVAR(range), _dist, 1, FAR_ALPHA_MIN, true];

[_rect, (_vehicle getVariable [QGVAR(rgb), UNKNOWN_RGB]) + [_alpha], [_vehicle, _dist] call FUNC(labelText)]
