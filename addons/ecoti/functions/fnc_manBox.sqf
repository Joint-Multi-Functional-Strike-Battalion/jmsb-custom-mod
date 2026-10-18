#include "script_component.hpp"
/*
 * Author: JMSB
 * One man's box for this frame: where it goes (FUNC(boxRect)), its colour
 * (FUNC(targetColour), faded with range) and its AiTR label.
 *
 * The box runs from his feet to just past his eyes (eyePos), so a crouched man
 * is shorter by as much as his eyes are lower; prone it lies along the ground,
 * back from his eyes the way he faces. Nothing about his model is read.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: View - [camPos, camFwd, camRight, camUp, window] <ARRAY>
 *
 * Return Value:
 * [rect, colour RGBA, [label, lines]] or [] when he is not drawn <ARRAY>
 *
 * Example:
 * [_unit, _view] call jmfsb_ecoti_fnc_manBox
 *
 * Public: No
 */

params ["_unit", "_view"];
_view params ["_camPos"];

if !(_unit getVariable [QGVAR(seen), false]) exitWith {[]};

private _eyes = ASLToAGL (eyePos _unit);
private _ground = ASLToAGL (getPosASLVisual _unit);
private _feet = if (stance _unit == "PRONE") then {
    private _dir = vectorDirVisual _unit;
    private _heel = _eyes vectorDiff ((vectorNormalized [_dir select 0, _dir select 1, 0]) vectorMultiply PRONE_LENGTH);
    [_heel select 0, _heel select 1, _ground select 2]
} else {
    _ground
};
private _crown = _eyes vectorAdd ((vectorNormalized (_eyes vectorDiff _feet)) vectorMultiply BODY_CROWN_PAST_EYES);

private _rect = [[_feet, _crown], MAN_BOX_MARGIN, _view] call FUNC(boxRect);
if (_rect isEqualTo []) exitWith {[]};

private _dist = _camPos distance _eyes;
private _alpha = linearConversion [GVAR(nearDistance), GVAR(range), _dist, 1, FAR_ALPHA_MIN, true];

[_rect, (_unit getVariable [QGVAR(rgb), UNKNOWN_RGB]) + [_alpha], [_unit, _dist] call FUNC(labelText)]
