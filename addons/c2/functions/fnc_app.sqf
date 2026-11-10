#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//C2, the tablet's measures app (design c2_app): pick a type, draw it,
 * name it, save. Drawing is the map TOOLS' ROUTE - press the points on the map
 * (a line two or more, an area three or more, a point one), then come back
 * here: the app takes the route as the measure's shape. Team leads and ATLs
 * create and delete; everyone sees the list and the measures on the map.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["c2", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};
([_display, "C2 MEASURES", APP_W, APP_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _y = _padY;
private _lead = [player] call FUNC(canEdit);

if (_lead) then {
    // the type
    [_body, [_pad, _y, _w, _rowH], "1  TYPE", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
    private _perRow = 5;
    private _chipW = (_w - _pad) / _perRow;
    {
        _x params ["_id", "_label"];
        [_body, [_pad + (_forEachIndex mod _perRow) * _chipW, _y + floor (_forEachIndex / _perRow) * (_rowH + _padY), _chipW - _pad, _rowH],
            _label, ["line", "fill"] select (_id isEqualTo GVAR(newType)), {
            params ["_ctrl"];
            GVAR(newType) = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""];
            {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, _id] call EFUNC(tacpad_apps,appPageButton);
    } forEach MEASURE_TYPES;
    _y = _y + 2 * (_rowH + _padY);

    // the shape: the map TOOLS' ROUTE
    private _route = missionNamespace getVariable [QEGVAR(maptools,route), []];
    [_body, [_pad, _y, _w, _rowH], format ["2  DRAW IT - map TOOLS > ROUTE: %1 POINT%2 DRAWN", count _route, ["S", ""] select (count _route isEqualTo 1)],
        [_muted, _ink] select (_route isNotEqualTo []), TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH + _padY;

    // the name
    [_body, [_pad, _y, _w * 0.2, _rowH], "3  NAME", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    private _edit = (ctrlParent _body) ctrlCreate ["RscEdit", -1, _body];
    _edit ctrlSetPosition [_w * 0.2, _y, _w * 0.45, _rowH];
    _edit ctrlSetText GVAR(newName);
    _edit ctrlSetTextColor _ink;
    _edit ctrlSetBackgroundColor _line;
    _edit ctrlCommit 0;
    _edit ctrlAddEventHandler ["KeyUp", {params ["_ctrl"]; GVAR(newName) = ctrlText _ctrl}];
    [_body, [_w * 0.68, _y, _w * 0.32 - _pad, _rowH], "4  SAVE", "fill", {
        [QGVAR(save), [GVAR(newType), GVAR(newName), missionNamespace getVariable [QEGVAR(maptools,route), []], player]] call CBA_fnc_serverEvent;
        GVAR(newName) = "";
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad_apps,appPageButton);
    _y = _y + _rowH + 2 * _padY;
    [_body, [0, _y, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
    _y = _y + _padY;
};

// the side's measures
private _mine = GVAR(measureList) select {(_x # 7) isEqualTo side group player};
[_body, [_pad, _y, _w, _rowH], format ["%1 MEASURE%2 ON THE MAP", count _mine, ["S", ""] select (count _mine isEqualTo 1)], _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
private _listTop = _y;
{
    _x params ["_mid", "_type", "_name", "_points", "_uid", "_by"];
    private _ry = _listTop + _forEachIndex * _rowH;
    if (_ry + _rowH > _h) exitWith {};
    ([_type] call FUNC(typeOf)) params ["", "_label", "_kind"];
    private _dist = round (([getPosATL player, _points, _kind isEqualTo "area"] call FUNC(nearest)) # 1);
    [_body, [_pad, _ry, _w * 0.5, _rowH], format ["%1 %2", _label, _name], [_ink, _accent] select (_type in ["loa", "no_fire_area"]), TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.5, _ry, _w * 0.3, _rowH], format ["%1  %2 M", toUpper _by, _dist], _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    if (_lead || {getPlayerUID player isEqualTo _uid}) then {
        [_body, [_w * 0.82, _ry, _w * 0.18 - _pad, _rowH * 0.9], "DELETE", "alarm", {
            params ["_ctrl"];
            [QGVAR(delete), [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""], player]] call CBA_fnc_serverEvent;
        }, _mid] call EFUNC(tacpad_apps,appPageButton);
    };
} forEach _mine;
