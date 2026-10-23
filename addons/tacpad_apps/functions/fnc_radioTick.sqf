#include "script_component.hpp"
/*
 * Author: JMSB
 * A tick square with its label, the RADIO board's one way of ticking a thing
 * (a squad or a man for a custom net; user, 2026-10-22: "allow rtos to add
 * custom channels"): filled ink when ticked, an ink outline when not, and dim
 * when the tick is not this cell's to change - a man on a net through his
 * squad is ticked by the squad's cell, not his own. The whole cell is the
 * press, so a thumb need not find the square. The square is kept square on
 * the screen the way the support checklist's box is.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Cell rectangle [x, y, w, h], relative to the body <ARRAY>
 * 2: Label <STRING>
 * 3: Ticked <BOOL>
 * 4: Dim - ticked through something else, drawn with no press <BOOL> (optional, default false)
 * 5: Pressed: called with [control] <CODE> (optional, default {} - no press)
 * 6: Data hung on the hit as QGVAR(pageData) <ANY> (optional, default nil)
 *
 * Return Value:
 * The hit, controlNull when there is no press <CONTROL>
 *
 * Example:
 * [_body, [_x, _y, _w, _h], "ALPHA", true, false, {...}, "ALPHA"] call jmfsb_tacpad_apps_fnc_radioTick
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_rect", [0, 0, 0, 0], [[]], 4],
    ["_label", "", [""]],
    ["_ticked", false, [false]],
    ["_dimmed", false, [false]],
    ["_onPress", {}, [{}]],
    ["_data", nil]
];

if (isNull _body) exitWith {controlNull};

_rect params ["_x", "_y", "_w", "_h"];
private _pad = PAD * HOST_W;
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _side = _h * TICK_BOX_K;
private _boxW = _side * (pixelW / pixelH);
private _box = [_x + _pad * 0.5, _y + (_h - _side) * 0.5, _boxW, _side];
private _colour = [_ink, _dim] select _dimmed;
if (_ticked) then {
    [_body, _box, _colour] call EFUNC(tacpad,drawFill);
} else {
    [_body, _box, _colour, RULE_THIN] call EFUNC(tacpad,drawFrame);
};
[_body, [_x + _boxW + _pad * 1.5, _y, _w - _boxW - _pad * 2, _h], _label, _colour, TEXT_LABEL, _ticked] call EFUNC(tacpad,drawText);

if (_dimmed || {_onPress isEqualTo {}}) exitWith {controlNull};

private _hit = [_body, _rect, _onPress] call EFUNC(tacpad,drawHit);
if (!isNil "_data") then {
    _hit setVariable [QGVAR(pageData), _data];
};
_hit
