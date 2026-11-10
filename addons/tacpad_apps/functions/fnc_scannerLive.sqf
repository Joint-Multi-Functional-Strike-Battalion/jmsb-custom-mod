#include "script_component.hpp"
/*
 * Author: YonV
 * What the EW SCANNER page's live lines say now, and the shape that decides
 * which lines there are (code review R8). FUNC(appScanner) builds the page
 * from these; its tick writes the next values into the same lines in place
 * (EFUNC(tacpad,liveApply)) and builds the page again only when the shape has
 * changed - the receiver taken or given, a reading row coming or going (a
 * drone inside two kilometres adds BEARING and RANGE), the number of alerts
 * shown, the scheme or the type size.
 *
 * Every number comes from EFUNC(hacking,scannerRead), the same cached sweep
 * the tiles read. The values come in the order the page draws them: the
 * headline, each reading row's value, then per alert shown its source and
 * its line.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [shape <ARRAY>, values [[text, RGBA], ...] <ARRAY>, the reading rows'
 * labels <ARRAY of STRINGs>, alerts shown <NUMBER>]
 *
 * Example:
 * ([] call jmfsb_tacpad_apps_fnc_scannerLive) params ["_shape", "_values", "_labels", "_alerts"]
 *
 * Public: No
 */

private _theme = [] call EFUNC(tacpad,theme);
_theme params ["", "_ink", "_accent"];
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];
private _frame = [_theme, EGVAR(tacpad,textScale), EGVAR(tacpad,uiScale), HOST_RECT, EGVAR(tacpad,displayMode)];

// A DENIED SCANNER IS A STATE, NOT AN EMPTY PAGE - and a page with nothing
// live on it.
if !([player] call EFUNC(hacking,hasScanner)) exitWith {[[false, _frame], [], [], 0]};

([] call EFUNC(hacking,scannerRead)) params
    ["_droneState", "_droneDist", "_droneDir", "_jam", "", "", "", ["_droneTag", ""]];

private _jamState = switch (true) do {
    case (_jam <= 0): {0};
    case (_jam >= SCANNER_JAM_CONTESTED): {2};
    default {1};
};

private _states = [_ink, TILE_AMBER, _accent];

// The worst thing the sweep found, in one word. A scanner's first answer is
// whether to care at all.
private _worst = _droneState max _jamState;
private _values = [[["SPECTRUM CLEAR", "SPECTRUM DEGRADED", "SPECTRUM CONTESTED"] select _worst, _states select _worst]];

// [label, value, colour]. Built as data so the page cannot drift out of order
// with itself, and so a reading with nothing to say is one line rather than a
// branch around the drawing.
private _rows = [
    ["AIR CONTACT", ["CLEAR", "INSIDE 2 KM", "INSIDE 1 KM"] select _droneState, _states select _droneState]
];

if (_droneState > 0) then {
    _rows pushBack ["BEARING", format ["%1 deg", [_droneDir, 3] call CBA_fnc_formatNumber], _states select _droneState];
    _rows pushBack ["RANGE", format ["%1 m", round _droneDist], _states select _droneState];
    if (_droneTag isNotEqualTo "") then {
        _rows pushBack ["AIRFRAME", toUpper _droneTag, _ink];
    };
} else {
    _rows pushBack ["", "Nothing unmanned and hostile within two kilometres.", _mute];
};

_rows pushBack ["JAMMING", ["CLEAR", format ["%1%2", round (_jam * 100), "%"]] select (_jamState > 0), _states select _jamState];
// NET STATE, MESH, CHANNEL AND FREQUENCY ARE THE RADIO APP'S - all four are
// questions about YOUR net, and it is the RADIO screen that is about your
// net. This page answers "what is in the air and how much of it is being sat
// on", and two screens carrying the same line is how they start disagreeing.

{
    _x params ["", "_value", "_colour"];
    _values pushBack [_value, _colour];
} forEach _rows;
private _labels = _rows apply {_x select 0};

// WHAT HAS BEEN DONE TO US LATELY: the newest entries of jmfsb_common's alert
// bus that are still live.
private _alerts = (missionNamespace getVariable [QEGVAR(common,alerts), []]) select {(_x param [4, 0]) > CBA_missionTime};
_alerts = _alerts select [0, SCANNER_ALERTS];
{
    _x params ["_src", "_txt", "_grid", ["_sev", 0]];
    _values pushBack [toUpper _src, _states select (_sev min 2)];
    _values pushBack [[_txt, format ["%1 - %2", _txt, _grid]] select (_grid isNotEqualTo ""), _ink];
} forEach _alerts;

[[true, _frame, _labels, count _alerts], _values, _labels, count _alerts]
