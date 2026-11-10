#include "script_component.hpp"
/*
 * Author: YonV
 * An image, tinted and squared. The suite's one concession to iconography: the
 * design specifies no icons anywhere, and squad health is the exception it
 * already makes for colour, so it is the one place a glyph says more than a
 * swatch - OK, bleeding, unconscious, dead read at a glance where four shades
 * of square have to be learned.
 *
 * SQUARED THROUGH THE PIXEL SCALES. A control given the same number for width
 * and height is a tall thin rectangle, because UI X and Y units are not the same
 * size. The caller gives a height and gets a square.
 *
 * Arguments:
 * 0: Parent <CONTROL>
 * 1: Position [x, y, h] - width is derived so the icon is square <ARRAY>
 * 2: Texture path <STRING>
 * 3: RGBA tint, [] to leave the texture's own colours <ARRAY> (optional, default [])
 *
 * Return Value:
 * The control <CONTROL>
 *
 * Example:
 * [_body, [_pad, _y, _rowH * 0.6], QPATHTOF(data\medical\ok_green.paa)] call jmfsb_tacpad_fnc_drawIcon
 *
 * Public: Yes
 */

params [["_parent", controlNull, [controlNull]], ["_pos", [0, 0, 0], [[]], 3], ["_texture", "", [""]], ["_tint", [], [[]]]];

if (isNull _parent || _texture == "") exitWith {controlNull};

_pos params ["_x", "_y", "_h"];

private _ctrl = (ctrlParent _parent) ctrlCreate [QGVAR(icon), -1, _parent];
_ctrl ctrlSetPosition [_x, _y, _h * pixelW / pixelH, _h];
_ctrl ctrlSetText _texture;
if (_tint isNotEqualTo []) then {
    _ctrl ctrlSetTextColor _tint;
};
_ctrl ctrlCommit 0;

_ctrl
