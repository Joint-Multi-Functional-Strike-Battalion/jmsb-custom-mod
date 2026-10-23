#include "script_component.hpp"
/*
 * Author: JMSB
 * The EW app's OVERVIEW tab: what he carries (sets, receiver, jammer, ISR,
 * GPS), the side's picture in three numbers, the MAP LAYER switch, and the
 * threat warnings of the last THREAT_SHOW_S, newest first, each with its time,
 * detail and what to do.
 *
 * Arguments:
 * 0: App body <CONTROL>
 * 1: Top y <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, 0.05] call jmfsb_ew_fnc_appOverview
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_top", 0, [0]]];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _accentText = ["accentText"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _w = (ctrlPosition _body) select 2;
private _pad = PAD * HOST_W;

GVAR(mine) params ["_side", "_tracks", "_nodes", "", "_kit", "_jam", "", "_threats"];
// His GPS as every reader takes it (FUNC(gpsState)), denial included.
private _gpsState = ([] call FUNC(gpsState)) select 0;
_kit params ["_receiver", "_hasJammer", "_vehicle", "_isr"];

// --- KIT ----------------------------------------------------------------------
private _sets = if (_nodes isEqualTo []) then {"NONE - NO RADIO, NO ES"} else {
    (_nodes apply {toUpper (_x select 1)}) joinString ", "
};
private _jamWord = switch (true) do {
    case (!_hasJammer): {"NONE"};
    case (_vehicle): {"VEHICLE"};
    default {"PACK"};
};
{
    _x params ["_label", "_value", "_hot"];
    [_body, [_pad, _top, _w * 0.3, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.3, _top, _w * 0.7 - _pad, _rowH], _value, [_ink, _accentText] select _hot, TEXT_TITLE, _hot] call EFUNC(tacpad,drawText);
    _top = _top + _rowH;
} forEach [
    ["SETS", _sets, _nodes isEqualTo []],
    ["RECEIVER", ["NO - SET-CLASS DF ONLY", "YES - DEDICATED DF, ALL BANDS, ANTI-SPOOF"] select _receiver, false],
    ["JAMMER", _jamWord, false],
    ["ISR", ["NO", "YES - CLASSIFY, SPOT, SPOOF, DECOYS"] select _isr, false],
    ["GPS", _gpsState, _gpsState isNotEqualTo GPS_GOOD]
];

// --- THE SIDE'S PICTURE ---------------------------------------------------------
_top = _top + _rowH * 0.4;
[_body, [0, _top, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_top = _top + _rowH * 0.3;
private _fixes = {(_x select 5) isNotEqualTo []} count _tracks;
private _jams = {(_x select 3) isEqualTo CLASS_JAM} count _tracks;
private _cellW = (_w - 2 * _pad) / 4;
{
    _x params ["_label", "_value"];
    [_body, [_pad + _forEachIndex * _cellW, _top, _cellW, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_pad + _forEachIndex * _cellW, _top + _rowH, _cellW, _rowH * 1.4], _value, _ink, TEXT_DISPLAY, true] call EFUNC(tacpad,drawText);
} forEach [["TRACKS", str count _tracks], ["FIXES", str _fixes], ["JAMMERS", str _jams], ["SIDE", _side]];
_top = _top + _rowH * 2.6;

[_body, [_pad, _top, _w * 0.3, _rowH], format ["MAP LAYER %1", ["OFF", "ON"] select GVAR(mapLayer)], GVAR(mapLayer), {
    GVAR(mapLayer) = !GVAR(mapLayer);
    {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call FUNC(appButton);
_top = _top + _rowH * 1.5;

// --- THREAT WARNINGS ------------------------------------------------------------
[_body, [0, _top, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_top = _top + _rowH * 0.3;
[_body, [_pad, _top, _w, _rowH], "THREAT WARNINGS", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
_top = _top + _rowH;

private _recent = _threats select {(CBA_missionTime - (_x select 0)) <= THREAT_SHOW_S};
reverse _recent;
if (_recent isEqualTo []) exitWith {
    [_body, [_pad, _top, _w - 2 * _pad, _rowH], "NONE IN THE LAST FEW MINUTES", ["dim"] call EFUNC(tacpad,theme), TEXT_BODY] call EFUNC(tacpad,drawText);
};
{
    _x params ["_t", "_kind", "_detail", "_advice"];
    [_body, [_pad, _top, _w * 0.12, _rowH], format ["%1 S", round (CBA_missionTime - _t)], _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.13, _top, _w * 0.2, _rowH], _kind, _accentText, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.34, _top, _w * 0.66 - _pad, _rowH], _detail, _ink, TEXT_BODY] call EFUNC(tacpad,drawText);
    if (_advice isNotEqualTo "") then {
        _top = _top + _rowH * 0.85;
        [_body, [_w * 0.34, _top, _w * 0.66 - _pad, _rowH], _advice, _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
    };
    _top = _top + _rowH;
} forEach _recent;
