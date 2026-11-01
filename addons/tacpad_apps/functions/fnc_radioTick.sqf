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

// THE ONE CHIP PRIMITIVE (notes, 2026-10-30): ticked is the ink filled,
// open an outline, and dim when the tick is not this cell's to change.
private _style = switch (true) do {
    case (_dimmed): {CHIP_DIM};
    case (_ticked): {CHIP_INK_FILL};
    default {CHIP_OUTLINE};
};
private _chipH = _h * CHIP_H_K;
[_body, [_x + _pad * 0.5, _y + (_h - _chipH) * 0.5], _chipH, _label, _style, _w - _pad] call EFUNC(tacpad,drawChip);

if (_dimmed || {_onPress isEqualTo {}}) exitWith {controlNull};

private _hit = [_body, _rect, _onPress] call EFUNC(tacpad,drawHit);
if (!isNil "_data") then {
    _hit setVariable [QGVAR(pageData), _data];
};
_hit
