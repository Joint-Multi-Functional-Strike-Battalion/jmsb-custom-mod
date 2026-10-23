#include "script_component.hpp"
/*
 * Author: JMSB
 * DRONES - FLEET: one row per drone on the players' side (FUNC(appDronesData)):
 * the drone, its link (DATA / JAM n% / LOST / NO RF), RF quality, battery and
 * task. A row is a button: it picks the drone the FEED shows. Under the list,
 * the enemy drones heard - the receiver sweep's nearest contact.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appDrones)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appDronesFleet
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _fleet = _ctx get "fleet";
private _pick = _ctx get "pick";
private _rowH = _ctx get "rowH";

private _enemy = [];
if (!isNil QEFUNC(hacking,scannerRead) && {[player] call EFUNC(hacking,hasScanner)}) then {
    _enemy = [] call EFUNC(hacking,scannerRead);
};
private _enemyState = _enemy param [0, 0];

([_body, _rect, "FLEET", format ["%1 OWN - %2 ENEMY", count _fleet, parseNumber (_enemyState > 0)]] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _tint = ["accentTint"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _cardH = _rowH * 2;

// DRONE LINK QUALITY BATT on the first line; the task under the name.
private _cols = [0, 0.4, 0.58, 0.82];
private _heads = ["DRONE", "LINK", "QUALITY", "BATT"];
private _cx = _cols apply {_left + _pad + _x * (_w - 2 * _pad)};
private _cw = [];
{
    _cw pushBack ((_cx param [_forEachIndex + 1, _left + _w - _pad]) - _x - _pad * 0.5);
} forEach _cx;

{
    [_body, [_x, _top, _cw select _forEachIndex, _rowH], _heads select _forEachIndex, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach _cx;
private _y = _top + _rowH;
[_body, [_left, _y, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

if (_fleet isEqualTo []) then {
    [_body, [_left + _pad, _y + _rowH * 0.2, _w - 2 * _pad, _rowH], "No drones up on your side.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
    _y = _y + _rowH * 1.4;
};

private _fit = floor ((_h - _rowH * 3) / _cardH) max 1;
{
    if (_forEachIndex >= _fit) then {break};
    _x params ["_uav", "_name", "_word", "_q", "_batt", "_task", "_mine", "_op"];
    private _ry = _y + _forEachIndex * _cardH;
    private _bad = _word in ["LOST", "NO RF"] || {(_word select [0, 3]) isEqualTo "JAM"};

    if (_uav isEqualTo _pick) then {
        [_body, [_left, _ry, _w, _cardH], _tint] call EFUNC(tacpad,drawFill);
    };
    [_body, [_cx select 0, _ry, _cw select 0, _rowH], _name, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_cx select 1, _ry, _cw select 1, _rowH], _word, ([_ink, _accent] select _bad), TEXT_LABEL, _bad] call EFUNC(tacpad,drawText);
    [_body, [_cx select 2, _ry, _cw select 2, _rowH], _q] call FUNC(appPageBar);
    [_body, [_cx select 3, _ry, _cw select 3, _rowH], format ["%1%2", round (_batt * PERCENT), "%"], _ink, TEXT_LABEL] call EFUNC(tacpad,drawText);
    [
        _body, [_cx select 0, _ry + _rowH, _w - 2 * _pad, _rowH],
        format ["%1%2", _task, ["", " - YOURS"] select _mine],
        ([_muted, _ink] select _mine), TEXT_LABEL, _mine
    ] call EFUNC(tacpad,drawText);
    [_body, [_left, _ry + _cardH - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    private _hit = [_body, [_left, _ry, _w, _cardH], {
        params ["_ctrl"];
        uiNamespace setVariable [QGVAR(dronesPick), _ctrl getVariable [QGVAR(pageData), objNull]];
        {["drones"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(pageData), _uav];
} forEach _fleet;

_y = _y + ((count _fleet) min _fit) * _cardH + _rowH * 0.3;

// The enemy, in one line - the ENEMY tab has the whole reading.
private _enemyLine = switch (true) do {
    case (_enemy isEqualTo []): {"ENEMY - NO RECEIVER"};
    case (_enemyState <= 0): {"ENEMY - NONE HEARD"};
    default {
        private _brg = [round (_enemy param [2, 0]), DRONES_BRG_DIGITS] call CBA_fnc_formatNumber;
        format ["ENEMY - 1 HEARD, BRG %1, %2 M", _brg, round (_enemy param [1, 0])]
    };
};
[_body, [_left + _pad, _y, _w - 2 * _pad, _rowH], _enemyLine, ([_muted, _accent] select (_enemyState > 0)), TEXT_LABEL, _enemyState > 0] call EFUNC(tacpad,drawText);
