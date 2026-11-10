#include "script_component.hpp"
/*
 * Author: YonV
 * A man's BFT member mark on a row of the SQUAD app (DESIGN_TABLET_APPS.md:
 * "BFT member icon and number"): the map's own outline and body in his fire
 * team's colour, his member number upright in the middle - the mark
 * jmfsb_bft_fnc_drawMembers puts on the map, so the roster and the map show
 * the same man the same way.
 *
 * THE NUMBER IS BFT'S (jmfsb_bft_fnc_memberNumber), asked softly as every
 * other surface asks it. Without jmfsb_bft there is no texture and no number
 * service: the mark is a square in his team's colour and the number is his
 * place in his group's own order, which is what BFT counts anyway.
 *
 * Arguments:
 * 0: Parent to draw into <CONTROL>
 * 1: Position [x, y, h] - the mark is square, h high <ARRAY>
 * 2: Unit <OBJECT>
 * 3: Faded - down or dead <BOOL> (optional, default false)
 *
 * Return Value:
 * Width drawn <NUMBER>
 *
 * Example:
 * [_body, [_x, _y, _h], _unit] call jmfsb_tacpad_apps_fnc_squadIcon
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_pos", [0, 0, 0], [[]], 3],
    ["_unit", objNull, [objNull]],
    ["_faded", false, [false]]
];

if (isNull _parent || {isNull _unit}) exitWith {0};

_pos params ["_left", "_top", "_h"];
private _w = _h * pixelW / pixelH;

private _bft = !isNil QEFUNC(bft,memberNumber);
private _number = if (_bft) then {
    [_unit] call EFUNC(bft,memberNumber)
} else {
    ((units group _unit) find _unit) + 1
};

private _alpha = [1, SQUAD_ICON_DOWN_ALPHA] select _faded;
private _teams = createHashMapFromArray SQUAD_ICON_TEAMS;
(_teams getOrDefault [assignedTeam _unit, _teams get "MAIN"]) params ["_fill", "_darkText"];
_fill = (_fill select [0, 3]) + [_alpha];

if (_bft) then {
    [_parent, [_left, _top, _h], SQUAD_ICON_OUTLINE, (SQUAD_ICON_OUTLINE_RGBA select [0, 3]) + [_alpha]] call EFUNC(tacpad,drawIcon);
    [_parent, [_left, _top, _h], SQUAD_ICON_BODY, _fill] call EFUNC(tacpad,drawIcon);
} else {
    [_parent, [_left, _top, _w, _h], _fill] call EFUNC(tacpad,drawFill);
};

[
    _parent, [_left, _top, _w, _h],
    [str _number, "-"] select (_number < 1),
    ([SQUAD_ICON_LIGHT_TEXT, SQUAD_ICON_DARK_TEXT] select _darkText) + [_alpha],
    TEXT_LABEL, true, "center"
] call EFUNC(tacpad,drawText);

_w
