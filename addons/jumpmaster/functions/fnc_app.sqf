#include "script_component.hpp"
/*
 * Author: JMSB
 * JUMPMASTER, the page (user, 2026-10-30): the jump type, the passes and the
 * exit, the flight path (PICK PATH ON MAP: red light, then green light), the
 * stick with each man's mask and chute and which pass he is on, the verdict,
 * and LAUNCH - or, while a run is up, its phase and ABORT. Squad leaders and
 * admins only; anyone else is told so.
 *
 * IT REDRAWS ITSELF every JM_REFRESH seconds while open, through the same
 * appAlive / appIdle pair every live app uses: the stick's kit and the run's
 * phase change under it.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jumpmaster", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

private _me = call CBA_fnc_currentUnit;
private _jm = [] call FUNC(isJumpmaster);
if (GVAR(passes) < 0) then {GVAR(passes) = GVAR(passesDefault)};
if (GVAR(exit) isEqualTo "") then {GVAR(exit) = GVAR(exitDefault)};
([GVAR(type)] call FUNC(ready)) params ["_rows", "_ready", "_missing"];
private _run = _me getVariable [QGVAR(run), []];
private _path = GVAR(red) isNotEqualTo [] && {GVAR(green) isNotEqualTo []};

private _scale = EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale);
([_display, APP_TITLE, APP_W, APP_H_BASE + (count _rows) * ROW_H * _scale] call EFUNC(tacpad,appFrame)) params ["_group", "_body"];
uiNamespace setVariable [QGVAR(group), _group];
if (isNull _body) exitWith {};
// The path is drawn under the page on this host's map.
[_display displayCtrl IDC_HOST_MAP] call FUNC(attach);

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _rowH = ROW_H * _scale * HOST_H;
private _w = (ctrlPosition _body) select 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
private _inner = _w - 2 * _pad;

// A button: an outline (filled when picked), a word, the press, and what it reads.
private _fnc_button = {
    params ["_rect", "_label", "_colour", "_code", ["_picked", false, [false]]];
    if (_picked) then {
        [_body, _rect, _colour] call EFUNC(tacpad,drawFill);
        [_body, _rect, _label, _ground, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    } else {
        [_body, _rect, _colour, RULE_THIN] call EFUNC(tacpad,drawFrame);
        [_body, _rect, _label, _colour, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    };
    private _hit = [_body, _rect, _code] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(data), _this param [5, -1]];
    _hit
};

private _y = _padY;
if (!_jm) exitWith {
    [_body, [_pad, _y, _inner, _rowH], "SQUAD LEADERS ONLY", _accent, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    [_body, [_pad, _y + _rowH, _inner, _rowH], "A JUMP IS RUN BY THE SQUAD LEADER, OR AN ADMIN", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

// ---------------------------------------------------------------- type ----
[_body, [_pad, _y, _w * 0.12, _btnH], "TYPE", _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
private _bx = _pad + _w * 0.12;
private _typeW = (_inner - _w * 0.12 - 2 * _pad) / 3;
{
    [[_bx, _y, _typeW, _btnH], _x, _accent, {
        params ["_ctrl"];
        GVAR(type) = _ctrl getVariable [QGVAR(data), TYPE_HALO];
        {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _x isEqualTo GVAR(type), _x] call _fnc_button;
    _bx = _bx + _typeW + _pad;
} forEach TYPES;
_y = _y + _btnH + _padY;

// ------------------------------------------------ passes, exit, altitude ----
[_body, [_pad, _y, _w * 0.12, _btnH], "PASSES", _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
_bx = _pad + _w * 0.12;
private _stepW = _btnH * HOST_H / HOST_W;
[[_bx, _y, _stepW, _btnH], "-", _ink, {
    GVAR(passes) = (GVAR(passes) - 1) max PASSES_MIN;
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
[_body, [_bx + _stepW, _y, _stepW, _btnH], str GVAR(passes), _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
[[_bx + 2 * _stepW, _y, _stepW, _btnH], "+", _ink, {
    GVAR(passes) = (GVAR(passes) + 1) min PASSES_MAX;
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
_bx = _bx + 3 * _stepW + _pad * 2;
[_body, [_bx, _y, _w * 0.08, _btnH], "EXIT", _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
_bx = _bx + _w * 0.08;
[[_bx, _y, _w * 0.2, _btnH], ["AUTO AT GREEN", "MANUAL"] select (GVAR(exit) isEqualTo EXIT_MANUAL), _ink, {
    GVAR(exit) = [EXIT_AUTO, EXIT_MANUAL] select (GVAR(exit) isEqualTo EXIT_AUTO);
    {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call _fnc_button;
_bx = _bx + _w * 0.2 + _pad;
[_body, [_bx, _y, _w - _bx - _pad, _btnH], format ["ALT %1 M", [GVAR(type)] call FUNC(typeAlt)], _mute, TEXT_BODY, true, "right"] call EFUNC(tacpad,drawText);
_y = _y + _btnH + _padY;

// ---------------------------------------------------------------- path ----
private _fnc_grid = {
    params ["_pos"];
    if (_pos isEqualTo []) then {"--"} else {[_pos] call EFUNC(maptools,gridText)}
};
[_body, [_pad, _y, _w * 0.3, _btnH], format ["RED %1", [GVAR(red)] call _fnc_grid], _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
[_body, [_pad + _w * 0.3, _y, _w * 0.3, _btnH], format ["GREEN %1", [GVAR(green)] call _fnc_grid], _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
[[_pad + _w * 0.62, _y, _inner - _w * 0.62, _btnH], "PICK PATH ON MAP", _ink, {["arm"] call FUNC(pick)}] call _fnc_button;
_y = _y + _btnH + _padY;

// ----------------------------------------------------------------- wind ----
// Where the stick lands (FUNC(drift); LAND on the map), and SHIFT PATH FOR
// WIND, which moves the lights upwind by it (FUNC(windShift)).
([GVAR(type)] call FUNC(drift)) params ["_dx", "_dy", "_canopyS"];
private _driftLen = vectorMagnitude [_dx, _dy, 0];
private _windFrom = (([0, 0, 0] getDir wind) + 180) mod 360;
private _windText = if (_driftLen < WIND_MIN_M) then {
    format ["WIND %1 M/S - NO DRIFT TO SPEAK OF", round (vectorMagnitude wind)]
} else {
    format ["WIND %1 M/S FROM %2 - STICK DRIFTS %3 TO %4 IN %5 S UNDER CANOPY", round (vectorMagnitude wind), [_windFrom] call EFUNC(maptools,bearingText), [_driftLen] call EFUNC(maptools,distanceText), [[0, 0, 0] getDir [_dx, _dy, 0]] call EFUNC(maptools,bearingText), round _canopyS]
};
[_body, [_pad, _y, _w * 0.62 - _pad, _btnH], _windText, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
if (_driftLen >= WIND_MIN_M && {GVAR(red) isNotEqualTo []} && {GVAR(green) isNotEqualTo []}) then {
    [[_pad + _w * 0.62, _y, _inner - _w * 0.62, _btnH], "SHIFT PATH FOR WIND", _ink, {
        [] call FUNC(windShift);
        {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call _fnc_button;
} else {
    [_body, [_pad + _w * 0.62, _y, _inner - _w * 0.62, _btnH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_body, [_pad + _w * 0.62, _y, _inner - _w * 0.62, _btnH], "SHIFT PATH FOR WIND", _dim, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
};
_y = _y + _btnH + _padY;

// --------------------------------------------------------------- stick ----
private _cols = [0, 0.08, 0.5, 0.66, 0.84];
private _cx = _cols apply {_pad + _x * _inner};
private _cw = [];
{
    _cw pushBack ((_cx param [_forEachIndex + 1, _pad + _inner]) - _x - _pad * 0.5);
} forEach _cx;
{
    [_body, [_cx select _forEachIndex, _y, _cw select _forEachIndex, _rowH], _x, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach ["#", "NAME", ["MASK", ""] select (GVAR(type) isEqualTo TYPE_STATIC), "CHUTE", "PASS"];
_y = _y + _rowH;
[_body, [_pad, _y, _inner, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _stick = [_rows apply {_x select 0}, GVAR(passes)] call FUNC(stick);
{
    _x params ["_unit", "_name", "_mask", "_chute"];
    private _ry = _y + _forEachIndex * _rowH;
    private _pass = (_stick findIf {_unit in _x}) + 1;
    private _ok = _mask && _chute;
    private _maskWord = switch (true) do {
        case (GVAR(type) isEqualTo TYPE_STATIC): {""};
        case (_mask): {"OK"};
        default {"NONE"};
    };
    {
        [_body, [_cx select _forEachIndex, _ry, _cw select _forEachIndex, _rowH], _x select 0, _x select 1, TEXT_BODY, _forEachIndex isEqualTo 1] call EFUNC(tacpad,drawText);
    } forEach [
        [str (_forEachIndex + 1), _ink],
        [toUpper _name, [_accent, _ink] select _ok],
        [_maskWord, [_accent, _ink] select _mask],
        [["NONE", "OK"] select _chute, [_accent, _ink] select _chute],
        [str _pass, _ink]
    ];
} forEach _rows;
_y = _y + (count _rows) * _rowH;
if (_rows isEqualTo []) then {
    [_body, [_pad, _y, _inner, _rowH], "NOBODY IN YOUR GROUP", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
    _y = _y + _rowH;
};

// ------------------------------------------------------------- verdict ----
_y = _y + _padY;
private _verdict = switch (true) do {
    case (_run isNotEqualTo []): {
        _run params ["_phase", "_pass", "_passes"];
        format ["RUN: %1 - PASS %2 OF %3", (PHASE_WORDS select {(_x select 0) isEqualTo _phase}) param [0, ["", "RUN"]] select 1, _pass, _passes]
    };
    case (!_path): {"NO FLIGHT PATH - PICK IT ON THE MAP"};
    case (!_ready): {format ["NOT READY - %1 WITHOUT A MASK OR A PARACHUTE", _missing]};
    default {format ["READY - %1 MEN, %2 PASS%3, %4 M", count _rows, GVAR(passes), ["", "ES"] select (GVAR(passes) > 1), [GVAR(type)] call FUNC(typeAlt)]};
};
[_body, [_pad, _y, _inner, _rowH], _verdict, [_mute, _accent] select (_run isNotEqualTo [] || _ready), TEXT_LABEL, true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

if (_run isNotEqualTo []) then {
    [[_pad, _y, _inner, _btnH], "ABORT - HOLD OVER THE DZ", _accent, {
        [] call FUNC(abort);
        {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call _fnc_button;
} else {
    if (_path && _ready) then {
        [[_pad, _y, _inner, _btnH], "LAUNCH", _accent, {
            [] call FUNC(launch);
            {[APP_ID, [], true] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, true] call _fnc_button;
    } else {
        [_body, [_pad, _y, _inner, _btnH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
        [_body, [_pad, _y, _inner, _btnH], "LAUNCH", _dim, TEXT_LABEL, true, "center", true] call EFUNC(tacpad,drawText);
    };
};

// ------------------------------------------------------- the refresh ----
if (GVAR(pfh) >= 0) then {
    [GVAR(pfh)] call CBA_fnc_removePerFrameHandler;
    GVAR(pfh) = -1;
};
GVAR(pfh) = [{
    params ["", "_handle"];
    if !([APP_ID] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        GVAR(pfh) = -1;
    };
    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    [APP_ID] call EFUNC(tacpad,openApp);
}, JM_REFRESH, []] call CBA_fnc_addPerFrameHandler;
