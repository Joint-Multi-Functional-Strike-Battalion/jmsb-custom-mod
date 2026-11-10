#include "script_component.hpp"
/*
 * Author: YonV
 * The C2 measures in the world, through the AiTR goggles (design c2_app.hud):
 * a line or an area drawn on the ground within LINE_RANGE, its name and
 * distance at its nearest point; a point as a plain dot beyond
 * POINT_DOT_RANGE, its icon, name and distance within. An LOA and a no-fire
 * area are red. Draw3D, this machine only.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_c2_fnc_draw
 *
 * Public: No
 */

if (GVAR(measureList) isEqualTo [] || {isNil QEFUNC(ecoti,isActive)} || {!([] call EFUNC(ecoti,isActive))}) exitWith {};

private _me = getPosATL player;
{
    _x params ["", "_type", "_name", "_points", "", "", "", "_side"];
    if (_side isNotEqualTo side group player) then {continue};
    ([_type] call FUNC(typeOf)) params ["", "_label", "_kind"];
    if (!GVAR(hud) && {!(_type in HUD_LOCKED)}) then {continue};
    private _colour = [COLOUR_LINE, COLOUR_RED] select (_type in ["loa", "no_fire_area"]);
    ([_me, _points, _kind isEqualTo "area"] call FUNC(nearest)) params ["_near", "_dist"];
    if (_kind isEqualTo "point") then {
        private _at = (_points # 0) vectorAdd [0, 0, HUD_UP];
        if (_dist > POINT_DOT_RANGE) then {
            drawIcon3D [DOT_ICON, _colour, _at, DOT_SIZE, DOT_SIZE, 0, "", 0];
        } else {
            drawIcon3D [POINT_ICON, _colour, _at, 1, 1, 0, format ["%1 %2  %3 M", _label, _name, round _dist], 2, HUD_SIZE, HUD_FONT, "center"];
        };
        continue;
    };
    if (_dist > LINE_RANGE) then {continue};
    private _path = +_points;
    if (_kind isEqualTo "area") then {_path pushBack (_points # 0)};
    for "_i" from 0 to (count _path - 2) do {
        drawLine3D [(_path # _i) vectorAdd [0, 0, LINE_LIFT], (_path # (_i + 1)) vectorAdd [0, 0, LINE_LIFT], _colour];
    };
    drawIcon3D ["", _colour, _near vectorAdd [0, 0, HUD_UP], 0, 0, 0, format ["%1 %2  %3 M", _label, _name, round _dist], 2, HUD_SIZE, HUD_FONT, "center"];
} forEach GVAR(measureList);
