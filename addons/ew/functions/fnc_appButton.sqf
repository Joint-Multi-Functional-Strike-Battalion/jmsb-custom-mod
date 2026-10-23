#include "script_component.hpp"
/*
 * Author: JMSB
 * One pressable cell of the EW app, in the suite's grammar: an outlined cell
 * with its label, or - when it is the selected one - the inverted accent
 * block. A disabled cell is drawn dim and takes no press. The data is hung on
 * the hit so the handler reads what it is for (GVAR(data)).
 *
 * Arguments:
 * 0: Parent <CONTROL>
 * 1: Position [x, y, w, h] <ARRAY>
 * 2: Label <STRING>
 * 3: Selected <BOOL>
 * 4: Handler, called with [hit control] <CODE>
 * 5: Data <ANY> (optional, default "")
 * 6: Enabled <BOOL> (optional, default true)
 *
 * Return Value:
 * The hit control, controlNull when disabled <CONTROL>
 *
 * Example:
 * [_body, [0, 0, 0.1, 0.02], "ES", true, {}, 1] call jmfsb_ew_fnc_appButton
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_pos", [0, 0, 0, 0], [[]], 4],
    ["_label", "", [""]],
    ["_selected", false, [false]],
    ["_handler", {}, [{}]],
    ["_data", ""],
    ["_enabled", true, [false]]
];

if (isNull _parent) exitWith {controlNull};

private _ground = ["ground"] call EFUNC(tacpad,theme);
private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

if (!_enabled) exitWith {
    [_parent, _pos, _dim, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_parent, _pos, _label, _dim, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    controlNull
};

if (_selected) then {
    [_parent, _pos, _accent] call EFUNC(tacpad,drawFill);
    [_parent, _pos, _label, _ground, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
} else {
    [_parent, _pos, _ink, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_parent, _pos, _label, _ink, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
};

private _hit = [_parent, _pos, _handler] call EFUNC(tacpad,drawHit);
_hit setVariable [QGVAR(data), _data];
_hit
