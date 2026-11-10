#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//TRAINING's VEHICLE RANGES tab (user, 2026-11-07). The ranges down the
 * left; the one picked on the right:
 *
 *     VEHICLES   what the module spawns
 *     RUN        direction (first leg; at the edge they turn and come back),
 *                how many side by side, speed - each starts on the module's
 *                choice; SPAWN, DESPAWN, SHOW ON MAP
 *     LIVE       status, moving, destroyed, despawns in
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: Top, relative to the body <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _top] call jmfsb_training_fnc_appVehicles
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_top", 0, [0]]];

if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _ranges = [] call FUNC(vehRanges);
if (_ranges isEqualTo []) exitWith {
    [_body, [_pad, _top, _w - 2 * _pad, _rowH * 2],
        "NO VEHICLE RANGES - PLACE JMSB - VEHICLE RANGE MODULES IN THE EDITOR", _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
};
if ((_ranges findIf {(_x # 0) isEqualTo GVAR(rangeSel)}) < 0) then {GVAR(rangeSel) = (_ranges # 0) # 0};

// ---- the list ----------------------------------------------------------------
private _listW = _w * 0.34;
{
    _x params ["_key", "", "_name"];
    private _y = _top + _forEachIndex * _rowH;
    if (_y + _rowH > _h) exitWith {};
    private _on = _key isEqualTo GVAR(rangeSel);
    private _status = ([_key] call FUNC(vehState)) # 0;
    if (_on) then {[_body, [0, _y, _listW, _rowH], _ink] call EFUNC(tacpad,drawFill)};
    [_body, [_pad, _y, _listW * 0.7, _rowH], toUpper _name, [_ink, _ground] select _on, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_listW * 0.7, _y, _listW * 0.3 - _pad, _rowH], toUpper _status,
        [[_muted, _accent] select (_status isEqualTo "live"), _ground] select _on, TEXT_LABEL, true, "right"] call EFUNC(tacpad,drawText);
    private _hit = [_body, [0, _y, _listW, _rowH], {
        params ["_ctrl"];
        GVAR(rangeSel) = _ctrl getVariable [QGVAR(range), ""];
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(range), _key];
} forEach _ranges;
[_body, [_listW + _pad, _top, RULE_THIN * pixelW, _h - _top], _line] call EFUNC(tacpad,drawFill);

// ---- the picked range ----------------------------------------------------------
private _range = _ranges select (_ranges findIf {(_x # 0) isEqualTo GVAR(rangeSel)});
_range params ["_key", "", "_name", "", "", "", "", "", "_settings"];
_settings params ["_classes", "_defDir", "_defCount", "_defSpeed", "_despawnMin"];

// A NEWLY PICKED RANGE STARTS ON ITS MODULE'S CHOICES.
if (GVAR(rangeLoaded) isNotEqualTo _key) then {
    GVAR(rangeLoaded) = _key;
    GVAR(rangeDir) = _defDir;
    GVAR(rangeCount) = _defCount;
    GVAR(rangeSpeed) = _defSpeed;
};
([_key] call FUNC(vehState)) params ["_status", "_vehicles", "_startedAt", "_by", "_dirLabel", "_speed", "_despawnAt"];

private _x0 = _listW + 3 * _pad;
private _rw = _w - _x0 - _pad;
private _y = _top;
[_body, [_x0, _y, _rw, _rowH], toUpper _name, _ink, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH + _padY;

// vehicles
[_body, [_x0, _y, _rw, _rowH], "VEHICLES - NO AMMO", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
private _names = _classes apply {toUpper getText (configFile >> "CfgVehicles" >> _x >> "displayName")};
[_body, [_x0, _y, _rw, _rowH], [_names joinString ", ", "NONE LOADED - SET THE MODULE'S VEHICLES"] select (_names isEqualTo []),
    [_ink, _accent] select (_names isEqualTo []), TEXT_BODY, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH + _padY;

// run: direction, two rows of four
[_body, [_x0, _y, _rw, _rowH], "FIRST LEG - THEY TURN AT THE EDGE AND COME BACK", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
private _perRow = count VR_DIRECTIONS / 2;
private _chipW = _rw / _perRow;
{
    _x params ["_label"];
    private _col = _forEachIndex mod _perRow;
    private _row = floor (_forEachIndex / _perRow);
    [_body, [_x0 + _col * _chipW, _y + _row * _rowH, _chipW - _pad, _rowH - _padY], _label,
        ["line", "fill"] select (_forEachIndex isEqualTo GVAR(rangeDir)), {
        params ["_ctrl"];
        GVAR(rangeDir) = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), 0];
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _forEachIndex] call EFUNC(tacpad_apps,appPageButton);
} forEach VR_DIRECTIONS;
_y = _y + 2 * _rowH + _padY;

// run: how many, how fast
private _fnc_count = {
    params ["_ctrl"];
    GVAR(rangeCount) = ((GVAR(rangeCount) + (_ctrl getVariable [QEGVAR(tacpad_apps,pageData), 0])) max 1) min VR_MAX_COUNT;
    {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};
private _fnc_speed = {
    params ["_ctrl"];
    GVAR(rangeSpeed) = ((GVAR(rangeSpeed) + (_ctrl getVariable [QEGVAR(tacpad_apps,pageData), 0])) max VR_SPEED_STEP) min VR_MAX_SPEED;
    {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
};
private _half = (_rw - _pad) / 2;
{
    _x params ["_x1", "_text", "_fnc", "_step"];
    [_body, [_x1, _y, _half * 0.2, _rowH], "-", "line", _fnc, -_step] call EFUNC(tacpad_apps,appPageButton);
    [_body, [_x1 + _half * 0.2, _y, _half * 0.6, _rowH], _text, _ink, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_x1 + _half * 0.8, _y, _half * 0.2, _rowH], "+", "line", _fnc, _step] call EFUNC(tacpad_apps,appPageButton);
} forEach [
    [_x0, format ["%1 AT ONCE", GVAR(rangeCount)], _fnc_count, 1],
    [_x0 + _half + _pad, format ["%1 KM/H", GVAR(rangeSpeed)], _fnc_speed, VR_SPEED_STEP]
];
_y = _y + _rowH + _padY;

// actions
private _live = _status isEqualTo "live";
private _bw = (_rw - 2 * _pad) / 3;
[_body, [_x0, _y, _bw, _rowH], ["SPAWN", "RESPAWN"] select _live, "fill", [{}, {
    params ["_ctrl"];
    [QGVAR(vehSpawn), [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""], GVAR(rangeDir), GVAR(rangeCount), GVAR(rangeSpeed), name player]] call CBA_fnc_serverEvent;
}] select (_classes isNotEqualTo []), _key] call EFUNC(tacpad_apps,appPageButton);
[_body, [_x0 + _bw + _pad, _y, _bw, _rowH], "DESPAWN", "alarm", [{}, {
    params ["_ctrl"];
    [QGVAR(vehClear), [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""]]] call CBA_fnc_serverEvent;
}] select _live, _key] call EFUNC(tacpad_apps,appPageButton);
[_body, [_x0 + 2 * (_bw + _pad), _y, _bw, _rowH], "SHOW ON MAP", "line", {
    params ["_ctrl"];
    [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""], 0, (VR_DIRECTIONS # GVAR(rangeDir)) # 1] call FUNC(showArea);
}, _key] call EFUNC(tacpad_apps,appPageButton);
_y = _y + _rowH + 2 * _padY;

// live
private _moving = {alive _x && {canMove _x}} count _vehicles;
private _left = [-1, (_despawnAt - serverTime) max 0] select (_live && _despawnAt > 0);
[_body, [_x0, _y, _rw, _rowH], "LIVE", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
[_body, [_x0, _y, _rw], [
    ["STATUS", toUpper _status, _live],
    ["MOVING", [format ["%1 / %2", _moving, count _vehicles], "-"] select !_live],
    ["DESTROYED / STOPPED", [str (count _vehicles - _moving), "-"] select !_live],
    ["DESPAWNS IN", [[_left, "MM:SS"] call BIS_fnc_secondsToString, ["-", "BY DESPAWN"] select _live] select (_left < 0)],
    ["SINCE SPAWN", [[(serverTime - _startedAt) max 0, "MM:SS"] call BIS_fnc_secondsToString, "-"] select (!_live || _startedAt < 0)],
    ["SET BY", [format ["%1, %2, %3 KM/H", toUpper _by, _dirLabel, _speed], "-"] select (_by isEqualTo "")]
], 2] call EFUNC(tacpad_apps,kvRow);
