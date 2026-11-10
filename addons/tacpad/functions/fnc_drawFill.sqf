#include "script_component.hpp"
/*
 * Author: YonV
 * A flat rectangle of colour. The whole suite is flat blocks and rules, so this
 * is most of what it draws.
 *
 * Arguments:
 * 0: Parent - a panel body or a controls group <CONTROL>
 * 1: Position [x, y, w, h], relative to the parent <ARRAY>
 * 2: RGBA <ARRAY>
 *
 * Return Value:
 * The control <CONTROL>
 *
 * Example:
 * [_body, [0, 0, _w, _h], _accent] call jmfsb_tacpad_fnc_drawFill
 *
 * Public: Yes
 */

params [["_parent", controlNull, [controlNull]], ["_pos", [0, 0, 0, 0], [[]], 4], ["_color", [0, 0, 0, 0], [[]]]];

if (isNull _parent) exitWith {controlNull};

private _ctrl = (ctrlParent _parent) ctrlCreate [QGVAR(fill), -1, _parent];
_ctrl ctrlSetPosition _pos;
_ctrl ctrlSetBackgroundColor _color;
_ctrl ctrlCommit 0;

_ctrl
