#include "script_component.hpp"
/*
 * Author: JMSB
 * The MEDIC app's patient page: the four monitored numbers, the status lines
 * and the body, for one man. BACK returns to the list; SHOW ON MAP closes the
 * app over him (FUNC(showOnMap)).
 *
 * WHERE A NUMBER CAME FROM IS PRINTED UNDER IT. A live device reading, a hand
 * check with its age and who took it, or NOT MONITORED - see FUNC(readVitals).
 * A medic reading a heart rate off a screen has to know whether it is now or
 * ten minutes ago.
 *
 * NOTHING FALLS OFF SILENTLY. The page is a fixed height and the rows grow
 * with the text size, so the status lines that do not fit are named in a last
 * line instead - the way the list counts the patients it cannot show.
 *
 * Arguments:
 * 0: Body to fill <CONTROL>
 * 1: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _unit] call jmfsb_medic_fnc_appPatient
 *
 * Public: No
 */

// The vitals tiles are this many rows tall; the left column is this share of
// the width.
#define TILE_ROWS 2.7
#define LEFT_SHARE 0.46

params [["_body", controlNull, [controlNull]], ["_unit", objNull, [objNull]]];

if (isNull _body || {isNull _unit}) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _accentText = ["accentText"] call EFUNC(tacpad,theme);
private _surface = ["surface"] call EFUNC(tacpad,theme);

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _btnH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;

([_unit] call FUNC(patientState)) params ["_state", "_heavy", "_grade"];

// ------------------------------------------------------------- the bar ----
// BACK left, the state in the middle, SHOW ON MAP right - the one action on
// the page that leaves it.
private _y = _padY;
private _backW = _w * 0.2;
[_body, [_pad, _y, _backW, _btnH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
[_body, [_pad, _y, _backW, _btnH], "< PATIENTS", _ink, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
[_body, [_pad, _y, _backW, _btnH], {
    GVAR(patient) = objNull;
    {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

private _chipW = _w * 0.26;
private _chipX = (_w - _chipW) / 2;
private _loud = _state in [STATE_ARREST, STATE_UNCON] || _heavy;
if (_loud) then {
    [_body, [_chipX, _y, _chipW, _btnH], _accent] call EFUNC(tacpad,drawFill);
} else {
    [_body, [_chipX, _y, _chipW, _btnH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
};
[
    _body, [_chipX, _y, _chipW, _btnH],
    STATE_WORDS select _state,
    [[_ink, _dim] select (_state isEqualTo STATE_DEAD), _ground] select _loud,
    TEXT_TITLE, true, "center", true
] call EFUNC(tacpad,drawText);

private _mapW = _w * 0.22;
private _mapX = _w - _pad - _mapW;
[_body, [_mapX, _y, _mapW, _btnH], _accent] call EFUNC(tacpad,drawFill);
[_body, [_mapX, _y, _mapW, _btnH], "SHOW ON MAP", _ground, TEXT_TITLE, true, "center"] call EFUNC(tacpad,drawText);
private _mapHit = [_body, [_mapX, _y, _mapW, _btnH], {
    params ["_ctrl"];
    [_ctrl getVariable [QGVAR(unit), objNull]] call FUNC(showOnMap);
}] call EFUNC(tacpad,drawHit);
_mapHit setVariable [QGVAR(unit), _unit];

_y = _y + _btnH + _padY;
[_body, [0, _y, _w, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + RULE_THICK * pixelH + _padY;

private _top = _y;
private _lw = _w * LEFT_SHARE;
[_body, [_lw, _top, RULE_THICK * pixelW, _h - _top], _ink] call EFUNC(tacpad,drawFill);

// ---------------------------------------------------------- the vitals ----
[_body, [_pad, _y, _lw - 2 * _pad, _rowH], "VITALS", _muted, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

private _tileW = (_lw - 3 * _pad) / 2;
private _tileH = _rowH * TILE_ROWS;
{
    _x params ["_label", "_value", "_unitText", "_source", "_live"];
    private _tx = _pad + (_forEachIndex mod 2) * (_tileW + _pad);
    private _ty = _y + floor (_forEachIndex / 2) * (_tileH + _padY);
    private _none = _value isEqualTo "--";

    // A live device reading gets the heavy edge; a hand reading or nothing,
    // the hairline.
    if (_live) then {
        [_body, [_tx, _ty, _tileW, _tileH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
    } else {
        [_body, [_tx, _ty, _tileW, _tileH], _surface] call EFUNC(tacpad,drawFill);
        [_body, [_tx, _ty, _tileW, _tileH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    };
    [_body, [_tx + _pad, _ty + _padY, _tileW * 0.7, _rowH * 0.6], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_tx + _tileW * 0.6, _ty + _padY, _tileW * 0.4 - _pad, _rowH * 0.6], _unitText, _dim, TEXT_LABEL, true, "right"] call EFUNC(tacpad,drawText);
    [_body, [_tx + _pad, _ty + _rowH * 0.7, _tileW - 2 * _pad, _rowH * 1.2], _value, [_ink, _dim] select _none, TEXT_DISPLAY, true] call EFUNC(tacpad,drawText);
    [_body, [_tx + _pad, _ty + _rowH * 1.9, _tileW - 2 * _pad, _rowH * 0.7], _source, [_muted, _dim] select _none, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
} forEach ([_unit] call FUNC(readVitals));
private _statusY = _y + 2 * (_tileH + _padY);

// ------------------------------------------------------------- status -----
// As many rows as fit above the bottom edge; past that, the last row that fits
// names the ones that did not.
private _status = [_unit, _grade] call FUNC(readStatus);
private _fit = floor ((_h - _statusY) / _rowH) max 0;
private _shown = [count _status, (_fit - 1) max 0] select (count _status > _fit);
{
    _x params ["_label", "_value", "_note", "_hot"];
    private _ry = _statusY + _forEachIndex * _rowH;
    [_body, [_pad, _ry, _lw * 0.3, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_lw * 0.3, _ry, _lw * 0.42, _rowH], _value, [[_ink, _dim] select (_value isEqualTo "--"), _accentText] select _hot, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_lw * 0.72, _ry, _lw * 0.28 - _pad, _rowH], _note, _dim, TEXT_LABEL, true, "right"] call EFUNC(tacpad,drawText);
    [_body, [_pad, _ry + _rowH - RULE_THIN * pixelH, _lw - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach (_status select [0, _shown]);
if (_shown < count _status && _fit > 0) then {
    private _missing = (_status select [_shown, count _status]) apply {_x # 0};
    [
        _body, [_pad, _statusY + _shown * _rowH, _lw - 2 * _pad, _rowH],
        format ["NOT SHOWN: %1 - LOWER THE TEXT SIZE", _missing joinString ", "],
        _accentText, TEXT_LABEL, true
    ] call EFUNC(tacpad,drawText);
};

// --------------------------------------------------------------- body -----
private _rx = _lw + RULE_THICK * pixelW + _pad;
private _rw = _w - _rx - _pad;
_y = _top;

[_body, [_rx, _y, _rw, _rowH], "BODY", _muted, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

private _cols = [["PART", 0], ["WOUNDS", 0.17], ["TQ", 0.43], ["BONE", 0.52], ["IV RUNNING", 0.72]];
private _fnc_cell = {
    params ["_index", "_text", "_colour", "_rowY", ["_size", TEXT_BODY], ["_bold", false]];
    private _at = (_cols # _index) # 1;
    private _next = (_cols param [_index + 1, ["", 1]]) # 1;
    [_body, [_rx + _at * _rw, _rowY, (_next - _at) * _rw - _pad, _rowH], _text, _colour, _size, _bold] call EFUNC(tacpad,drawText);
};
{
    [_forEachIndex, _x # 0, _muted, _y, TEXT_LABEL, true] call _fnc_cell;
} forEach _cols;
_y = _y + _rowH;
[_body, [_rx, _y, _rw, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + RULE_THICK * pixelH;

private _tableY = _y;
private _ivCount = 0;
private _tqCount = 0;
{
    _x params ["_part", "_open", "_bandaged", "_bleeding", "_tq", "_bone", "_ivs", "_boneHot"];
    private _ry = _tableY + _forEachIndex * _rowH;
    _ivCount = _ivCount + count _ivs;
    if (_tq) then {_tqCount = _tqCount + 1};

    [0, _part, _ink, _ry, TEXT_BODY, true] call _fnc_cell;

    private _wounds = [];
    if (_open > 0) then {_wounds pushBack format ["%1 OPEN", _open]};
    if (_bandaged > 0) then {_wounds pushBack format ["%1 BAND", _bandaged]};
    [1, [_wounds joinString " / ", "-"] select (_wounds isEqualTo []), [[_ink, _dim] select (_wounds isEqualTo []), _accentText] select _bleeding, _ry, TEXT_BODY, _bleeding] call _fnc_cell;

    // A tourniquet is a chip, because a forgotten one costs the limb.
    if (_tq) then {
        private _at = (_cols # 2) # 1;
        [_body, [_rx + _at * _rw, _ry + _padY * 0.5, ((_cols # 3) # 1 - _at) * _rw - _pad, _rowH - _padY], _accent] call EFUNC(tacpad,drawFill);
        [_body, [_rx + _at * _rw, _ry, ((_cols # 3) # 1 - _at) * _rw - _pad, _rowH], "TQ", _ground, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);
    } else {
        [2, "-", _dim, _ry, TEXT_BODY] call _fnc_cell;
    };

    [3, [_bone, "-"] select (_bone isEqualTo ""), [[_ink, _dim] select (_bone isEqualTo ""), _accentText] select _boneHot, _ry, TEXT_BODY, _boneHot] call _fnc_cell;
    [4, [_ivs joinString ", ", "-"] select (_ivs isEqualTo []), [_ink, _dim] select (_ivs isEqualTo []), _ry, TEXT_LABEL] call _fnc_cell;

    [_body, [_rx, _ry + _rowH - RULE_THIN * pixelH, _rw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach ([_unit] call FUNC(readBody));

_y = _tableY + (count BODY_PARTS) * _rowH + _padY;
[
    _body, [_rx, _y, _rw, _rowH],
    format ["%1 TOURNIQUET%2 - %3 IV%4 RUNNING", _tqCount, ["S", ""] select (_tqCount isEqualTo 1), _ivCount, ["S", ""] select (_ivCount isEqualTo 1)],
    [_muted, _accentText] select (_tqCount > 0), TEXT_LABEL, true, "left"
] call EFUNC(tacpad,drawText);
_y = _y + _rowH * 1.5;

// What the screen is and is not telling the medic - see FUNC(readVitals) and
// FUNC(readStatus). Only the lines that fit above the bottom edge are drawn.
{
    private _ly = _y + _forEachIndex * _rowH * 0.8;
    if (_ly + _rowH > _h) then {break};
    [_body, [_rx, _ly, _rw, _rowH], _x, _dim, TEXT_LABEL, false] call EFUNC(tacpad,drawText);
} forEach [
    "THE TABLET'S EKG AND PULSE OX READ HR, SPO2 AND RHYTHM LIVE.",
    "BP NEEDS A CUFF OR THE AED'S NIBP.  RR NEEDS THE CAPNO.",
    "A DEVICE ON THE PATIENT WINS OVER THE TABLET'S LEADS.",
    "OTHERWISE THE LAST HAND CHECK, WITH ITS AGE."
];
