#include "script_component.hpp"
/*
 * Author: JMSB
 * The EW app's ES tab (DESIGN_EW "ES"): the SPECTRUM where he stands - per
 * band, the noise above the floor, which is what a jammer looks like from
 * inside its field - and the side's TRACKS: id, what it is (FUNC(classShown)),
 * band, strength, the fix with its error or the latest bearing, confidence
 * and age. Tapping a track closes the app and puts the map on it.
 *
 * Arguments:
 * 0: App body <CONTROL>
 * 1: Top y <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, 0.05] call jmfsb_ew_fnc_appEs
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_top", 0, [0]]];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

GVAR(mine) params ["", "_tracks", "", "_spectrum", "_kit"];
private _isr = _kit param [3, false];

// --- SPECTRUM -------------------------------------------------------------------
[_body, [_pad, _top, _w, _rowH], "SPECTRUM HERE - NOISE ABOVE FLOOR", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
_top = _top + _rowH;
{
    _x params ["_band", "_noise", "_floor"];
    private _rise = (_noise - _floor) max 0;
    private _barX = _pad + _w * 0.12;
    private _barW = _w * 0.68;
    [_body, [_pad, _top, _w * 0.12, _rowH], _band, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_barX, _top + _rowH * 0.3, _barW, _rowH * 0.4], _line] call EFUNC(tacpad,drawFill);
    if (_rise > 0) then {
        [_body, [_barX, _top + _rowH * 0.3, _barW * ((_rise / SPECTRUM_SPAN_DB) min 1), _rowH * 0.4], _accent] call EFUNC(tacpad,drawFill);
    };
    [_body, [_barX + _barW, _top, _w - _barX - _barW - _pad, _rowH], format ["+%1 DB", _rise], [_muted, _accent] select (_rise > 0), TEXT_BODY, _rise > 0, "right"] call EFUNC(tacpad,drawText);
    _top = _top + _rowH;
} forEach _spectrum;

// --- TRACKS ---------------------------------------------------------------------
_top = _top + _rowH * 0.4;
private _cols = [["ID", 0], ["SIGNAL", 0.08], ["BAND", 0.40], ["DBM", 0.50], ["FIX / BEARING", 0.60], ["CONF", 0.84], ["AGE", 0.92]];
{
    _x params ["_label", "_at"];
    [_body, [_pad + _at * (_w - 2 * _pad), _top, _w * 0.3, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach _cols;
_top = _top + _rowH;
[_body, [0, _top, _w, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

if (_tracks isEqualTo []) exitWith {
    [_body, [_pad, _top + _padY, _w - 2 * _pad, _rowH], "NOTHING HEARD - NO EMITTER IN REACH OF YOUR SIDE'S SETS", ["dim"] call EFUNC(tacpad,theme), TEXT_BODY] call EFUNC(tacpad,drawText);
};

private _limit = _h - _rowH;
private _hidden = 0;
{
    if (_top + _rowH > _limit) then {
        _hidden = _hidden + 1;
        continue;
    };
    _x params ["_id", "_band", "_dbm", "_class", "", "_fix", "_fixErr", "_conf", "_last", "_cuts"];
    private _where = if (_fix isNotEqualTo []) then {
        format ["%1 +-%2", mapGridPosition _fix, _fixErr]
    } else {
        private _cut = _cuts param [count _cuts - 1, []];
        if (_cut isEqualTo []) then {"-"} else {format ["BRG %1 +-%2", _cut select 1, _cut select 2]}
    };
    private _hot = _class in [CLASS_JAM, CLASS_SPOOF, CLASS_VIDEO];
    private _cells = [
        _id, [_x, _isr] call FUNC(classShown), _band, str _dbm, _where,
        format ["%1%2", round (_conf * 100), "%"], format ["%1S", round (CBA_missionTime - _last)]
    ];
    {
        (_cols select _forEachIndex) params ["", "_at"];
        private _next = (_cols param [_forEachIndex + 1, ["", 1]]) select 1;
        [_body, [_pad + _at * (_w - 2 * _pad), _top, (_next - _at) * (_w - 2 * _pad), _rowH], _x, [_ink, _accent] select (_hot && _forEachIndex == 1), TEXT_BODY, _forEachIndex == 1] call EFUNC(tacpad,drawText);
    } forEach _cells;
    [_body, [0, _top + _rowH - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    private _at = if (_fix isNotEqualTo []) then {_fix} else {(_cuts param [count _cuts - 1, [[0, 0]]]) select 0};
    private _hit = [_body, [0, _top, _w, _rowH], {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(data), []]] call FUNC(showOnMap);
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(data), _at];
    _top = _top + _rowH;
} forEach _tracks;

if (_hidden > 0) then {
    [_body, [_pad, _limit, _w - 2 * _pad, _rowH], format ["%1 MORE TRACKS - SEE THE MAP LAYER", _hidden], _muted, TEXT_LABEL, true, "right"] call EFUNC(tacpad,drawText);
};
