#include "script_component.hpp"
/*
 * Author: YonV
 * TAC//TRAINING's TRAINING AREAS tab (user, 2026-11-07). The ta_* areas down
 * the left; the one picked on the right:
 *
 *     INTEL        size, buildings, building positions, how many it holds
 *                  (FUNC(areaIntel))
 *     ENEMY        density - the number it puts there, worked out from the
 *                  intel - the faction, and the patrol radius past the edge
 *                  (not for a CQB house); SPAWN, CLEAR, SHOW ON MAP
 *     LIVE         status, enemy left, killed, trainees inside right now
 *     AFTER ACTION first shot to the last enemy down, killed, trainees down,
 *                  and who set it up with what (FUNC(areaState))
 *
 * Arguments:
 * 0: Body to draw into <CONTROL>
 * 1: Top, relative to the body <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _top] call jmfsb_training_fnc_appAreas
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

private _areas = [] call FUNC(areas);
if (_areas isEqualTo []) exitWith {
    [_body, [_pad, _top, _w - 2 * _pad, _rowH * 2],
        "NO TRAINING AREAS - PLACE JMSB - TRAINING AREA MODULES IN THE EDITOR", _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
};

if ((_areas findIf {(_x # 0) isEqualTo GVAR(areaSel)}) < 0) then {GVAR(areaSel) = (_areas # 0) # 0};
private _typeName = createHashMapFromArray TA_TYPES;

// ---- the list ----------------------------------------------------------------
private _listW = _w * 0.34;
{
    _x params ["_marker", "_type", "_name"];
    private _y = _top + _forEachIndex * _rowH;
    if (_y + _rowH > _h) exitWith {};
    private _on = _marker isEqualTo GVAR(areaSel);
    private _status = ([_marker] call FUNC(areaState)) # 0;
    if (_on) then {[_body, [0, _y, _listW, _rowH], _ink] call EFUNC(tacpad,drawFill)};
    private _fg = [_ink, _ground] select _on;
    [_body, [_pad, _y, _listW * 0.55, _rowH], toUpper _name, _fg, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_listW * 0.55, _y, _listW * 0.2, _rowH], _typeName getOrDefault [_type, toUpper _type], [_muted, _ground] select _on, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    [_body, [_listW * 0.75, _y, _listW * 0.25 - _pad, _rowH], toUpper _status,
        [[_muted, _accent] select (_status isEqualTo "live"), _ground] select _on, TEXT_LABEL, true, "right"] call EFUNC(tacpad,drawText);
    private _hit = [_body, [0, _y, _listW, _rowH], {
        params ["_ctrl"];
        GVAR(areaSel) = _ctrl getVariable [QGVAR(marker), ""];
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(marker), _marker];
} forEach _areas;
[_body, [_listW + _pad, _top, RULE_THIN * pixelW, _h - _top], _line] call EFUNC(tacpad,drawFill);

// ---- the picked area ------------------------------------------------------------
private _area = _areas select (_areas findIf {(_x # 0) isEqualTo GVAR(areaSel)});
_area params ["_marker", "_type", "_name", "", "", "", "", "", ["_defaults", ["", 1, 0, []]]];
_defaults params ["_defFaction", "_defDensity", "_defPatrol", "_offered"];

// A NEWLY PICKED AREA STARTS ON ITS MODULE'S CHOICES: density, patrol radius,
// the factions it offers and the one it starts on.
if (GVAR(areaLoaded) isNotEqualTo _marker) then {
    GVAR(areaLoaded) = _marker;
    GVAR(density) = _defDensity;
    GVAR(patrolOut) = _defPatrol;
    private _all = [side group player] call FUNC(factions);
    GVAR(factionList) = [_all, _all select {(_x # 0) in _offered}] select (_offered isNotEqualTo []);
    GVAR(factionIdx) = (GVAR(factionList) findIf {(_x # 0) isEqualTo _defFaction}) max 0;
};
([_marker] call FUNC(areaIntel)) params ["", "_m2", "_radius", "_buildings", "_positions", "_capacity", "_menBy", "_staticsBy", "_vehiclesBy"];
private _state = [_marker] call FUNC(areaState);
_state params ["_status", "_spawned", "_killed", "_startedAt", "_shotAt", "_clearedAt", "_casualties", "_faction", "_density", "_patrol", "_by"];

private _x0 = _listW + 3 * _pad;
private _rw = _w - _x0 - _pad;
private _y = _top;
[_body, [_x0, _y, _rw, _rowH], format ["%1 - %2", toUpper _name, _typeName getOrDefault [_type, toUpper _type]], _ink, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH + _padY;

// intel
[_body, [_x0, _y, _rw, _rowH], "INTEL", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
_y = _y + ([_body, [_x0, _y, _rw], [
    ["SIZE", format ["%1 HA", (_m2 / 10000) toFixed 1]],
    ["RADIUS", format ["%1 M", _radius]],
    ["BUILDINGS", str _buildings],
    ["POSITIONS", str _positions],
    ["HOLDS", format ["%1 MEN", _capacity]]
], 3] call EFUNC(tacpad_apps,kvRow)) + _padY;

// enemy: density
[_body, [_x0, _y, _rw, _rowH], "ENEMY", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
private _chipW = _rw / count DENSITIES;
{
    _x params ["", "_label"];
    [_body, [_x0 + _forEachIndex * _chipW, _y, _chipW - _pad, _rowH], format ["%1  %2", _label, _menBy # _forEachIndex],
        ["line", "fill"] select (_forEachIndex isEqualTo GVAR(density)), {
        params ["_ctrl"];
        GVAR(density) = _ctrl getVariable [QEGVAR(tacpad_apps,pageData), 1];
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _forEachIndex] call EFUNC(tacpad_apps,appPageButton);
} forEach DENSITIES;
_y = _y + _rowH + _padY;
if (_type isEqualTo "base") then {
    [_body, [_x0, _y, _rw, _rowH], format ["+ %1 STATIC WEAPONS, %2 ARMED VEHICLES", _staticsBy # GVAR(density), _vehiclesBy # GVAR(density)], _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
};

// enemy: faction
private _factionCount = count GVAR(factionList);
if (_factionCount isEqualTo 0) then {
    [_body, [_x0, _y, _rw, _rowH], "NO ENEMY FACTION LOADED", _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
} else {
    GVAR(factionIdx) = (GVAR(factionIdx) max 0) min (_factionCount - 1);
    private _fnc_step = {
        params ["_ctrl"];
        GVAR(factionIdx) = (GVAR(factionIdx) + (_ctrl getVariable [QEGVAR(tacpad_apps,pageData), 1]) + count GVAR(factionList)) mod count GVAR(factionList);
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    };
    [_body, [_x0, _y, _rw * 0.1, _rowH], "<", "line", _fnc_step, -1] call EFUNC(tacpad_apps,appPageButton);
    [_body, [_x0 + _rw * 0.12, _y, _rw * 0.76, _rowH], toUpper ((GVAR(factionList) # GVAR(factionIdx)) # 1), _ink, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_x0 + _rw * 0.9, _y, _rw * 0.1, _rowH], ">", "line", _fnc_step, 1] call EFUNC(tacpad_apps,appPageButton);
};
_y = _y + _rowH + _padY;

// enemy: patrol radius past the edge - a shoot house has none
if (_type isNotEqualTo "cqb") then {
    private _fnc_patrol = {
        params ["_ctrl"];
        GVAR(patrolOut) = ((GVAR(patrolOut) + (_ctrl getVariable [QEGVAR(tacpad_apps,pageData), 0])) max 0) min PATROL_MAX;
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    };
    [_body, [_x0, _y, _rw * 0.1, _rowH], "-", "line", _fnc_patrol, -PATROL_STEP] call EFUNC(tacpad_apps,appPageButton);
    [_body, [_x0 + _rw * 0.12, _y, _rw * 0.76, _rowH], format ["PATROLS %1 M PAST THE EDGE", GVAR(patrolOut)], _ink, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    [_body, [_x0 + _rw * 0.9, _y, _rw * 0.1, _rowH], "+", "line", _fnc_patrol, PATROL_STEP] call EFUNC(tacpad_apps,appPageButton);
    _y = _y + _rowH + _padY;
};

// actions
private _bw = (_rw - 2 * _pad) / 3;
[_body, [_x0, _y, _bw, _rowH], "SPAWN", "fill", [{}, {
    params ["_ctrl"];
    [QGVAR(areaSpawn), [
        _ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""],
        (GVAR(factionList) # GVAR(factionIdx)) # 0,
        GVAR(density), GVAR(patrolOut), name player
    ]] call CBA_fnc_serverEvent;
}] select (_factionCount > 0), _marker] call EFUNC(tacpad_apps,appPageButton);
[_body, [_x0 + _bw + _pad, _y, _bw, _rowH], "CLEAR", "alarm", [{}, {
    params ["_ctrl"];
    [QGVAR(areaClear), [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""]]] call CBA_fnc_serverEvent;
}] select (_status isEqualTo "live"), _marker] call EFUNC(tacpad_apps,appPageButton);
[_body, [_x0 + 2 * (_bw + _pad), _y, _bw, _rowH], "SHOW ON MAP", "line", {
    params ["_ctrl"];
    [_ctrl getVariable [QEGVAR(tacpad_apps,pageData), ""], GVAR(patrolOut)] call FUNC(showArea);
}, _marker] call EFUNC(tacpad_apps,appPageButton);
_y = _y + _rowH + 2 * _padY;

// live
private _shape = _area select [3, 5];
private _inside = {alive _x && _x inArea _shape} count (allPlayers - entities "HeadlessClient_F");
[_body, [_x0, _y, _rw, _rowH], "LIVE", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
_y = _y + ([_body, [_x0, _y, _rw], [
    ["STATUS", toUpper _status, _status isEqualTo "live"],
    ["ENEMY LEFT", [format ["%1 / %2", _spawned - _killed, _spawned], "-"] select (_status isEqualTo "idle")],
    ["KILLED", str _killed],
    ["TRAINEES IN AREA", str _inside]
], 2] call EFUNC(tacpad_apps,kvRow)) + _padY;

// after action
private _fnc_clock = {
    params ["_from", "_to"];
    if (_from < 0 || _to < 0) exitWith {"-"};
    [(_to - _from) max 0, "MM:SS"] call BIS_fnc_secondsToString
};
private _end = [_clearedAt, serverTime] select (_status isEqualTo "live");
[_body, [_x0, _y, _rw, _rowH], "AFTER ACTION", _muted, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;
[_body, [_x0, _y, _rw], [
    ["FIRST SHOT TO CLEAR", [[_shotAt, _clearedAt] call _fnc_clock, format ["%1 SO FAR", [_shotAt, _end] call _fnc_clock]] select (_status isEqualTo "live")],
    ["SINCE SPAWN", [_startedAt, _end] call _fnc_clock],
    ["ENEMY KILLED", str _killed],
    ["TRAINEES DOWN", str _casualties, _casualties > 0],
    ["FACTION", toUpper _faction],
    ["SET BY", [format ["%1, %2, %3 M", toUpper _by, _density, _patrol], "-"] select (_by isEqualTo "")]
], 2] call EFUNC(tacpad_apps,kvRow);
