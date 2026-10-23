#include "script_component.hpp"
/*
 * Author: JMSB
 * EW SCANNER, full size: everything the hand-held hears, on one page.
 *
 * ONE PAGE, NOT THREE. The archived device suite split the same reading across a
 * drone page, a jamming page and a mesh page, and the DRONES and JAM tiles here
 * still each open their own screen - which is right for a tile, because a tile
 * answers one question. This is the other thing a scanner is for: the whole
 * spectrum picture at once, when what you want to know is not "how bad is the
 * jamming" but "what is going on around me".
 *
 * IT PRESENTS, IT DOES NOT MEASURE. Every number comes from
 * EFUNC(hacking,scannerRead) - the same sweep, on the same cache, that the tile
 * band and the drone screen read - so no two screens in the suite can disagree
 * about what is overhead. The alarms are the hacking addon's roster and the
 * alert log is jmfsb_common's bus; this owns neither.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

if (isNil QEFUNC(hacking,scannerRead)) exitWith {
    ["SCANNER", "The intrusion suite is not loaded.", "high"] call EFUNC(messaging,notify);
};

// Shorter since the alarms and the net rows left - a frame sized for content
// that moved out is a frame with a hole in the bottom.
([_display, "EW SCANNER", 0.46, 0.56] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

// A DENIED SCANNER IS A STATE, NOT AN EMPTY PAGE. A mission can take the
// receiver off a man, and a page of dashes does not say that anybody did.
if !([player] call EFUNC(hacking,hasScanner)) exitWith {
    [_body, [_pad, _padY, _w - 2 * _pad, _rowH], "NO RECEIVER", _accent, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    [
        _body, [_pad, _padY + _rowH * 1.2, _w - 2 * _pad, _rowH],
        "This unit is not carrying a spectrum receiver.", _mute, TEXT_TITLE
    ] call EFUNC(tacpad,drawText);
};

([] call EFUNC(hacking,scannerRead)) params
    ["_droneState", "_droneDist", "_droneDir", "_jam", "_chanText", "_freqText", "_mesh", ["_droneTag", ""]];

private _jamState = switch (true) do {
    case (_jam <= 0): {0};
    case (_jam >= 0.75): {2};
    default {1};
};

private _states = [_ink, [0.85, 0.65, 0.15, 1], _accent];

// ------------------------------------------------------------- the hero -----
// The worst thing the sweep found, in one word. A scanner's first answer is
// whether to care at all.
private _worst = _droneState max _jamState;
private _band = ["SPECTRUM CLEAR", "SPECTRUM DEGRADED", "SPECTRUM CONTESTED"] select _worst;

private _heroH = _rowH * 2.2;
[_body, [_pad, _padY, _w - 2 * _pad, _heroH * 0.7], _band, (_states select _worst), TEXT_DISPLAY, true] call EFUNC(tacpad,drawText);
// The sub-line was your channel - radio information, which is the RADIO
// app's. The sweep page speaks spectrum only now.

private _y = _padY + _heroH;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// ------------------------------------------------------------- the rows -----
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
    _x params ["_label", "_value", "_colour"];
    private _ry = _y + _forEachIndex * _rowH;

    [_body, [_pad, _ry, _w * 0.34, _rowH], _label, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_w * 0.36, _ry, _w * 0.64 - _pad, _rowH], _value, _colour, TEXT_TITLE, true, "right"] call EFUNC(tacpad,drawText);
    [_body, [_pad, _ry + _rowH - RULE_THIN * pixelH, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _rows;

_y = _y + (count _rows) * _rowH + _padY;

// NO ALARMS HERE ANY MORE. The roster is the TIMER app's - it already draws
// and sizes for it - and the same list on two pages is two pages to disagree.

// ------------------------------------------------------------ the log -------
// WHAT HAS BEEN DONE TO US LATELY. Every jmfsb system that fires, flies or
// shells at players posts to one bus, and this is where it can be read back: a
// popup answers "what was that" for three seconds, this answers it for as long
// as the entry lives.
_y = _y + _padY;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_y = _y + _padY;
[_body, [_pad, _y, _w - 2 * _pad, _rowH], "RECENT ALERTS", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

private _alerts = (missionNamespace getVariable [QEGVAR(common,alerts), []]) select {(_x param [4, 0]) > CBA_missionTime};

if (_alerts isEqualTo []) then {
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NOTHING IN THE LAST FEW MINUTES", _dim, TEXT_TITLE] call EFUNC(tacpad,drawText);
} else {
    {
        _x params ["_src", "_txt", "_grid", ["_sev", 0]];
        private _ay = _y + _forEachIndex * _rowH;

        [_body, [_pad, _ay, _w * 0.2, _rowH], toUpper _src, (_states select (_sev min 2)), TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
        [
            _body, [_w * 0.22, _ay, _w * 0.78 - _pad, _rowH],
            [_txt, format ["%1 - %2", _txt, _grid]] select (_grid isNotEqualTo ""),
            _ink, TEXT_BODY
        ] call EFUNC(tacpad,drawText);
        if (_forEachIndex >= 3) exitWith {};
    } forEach _alerts;
};

// The page is a live readout, so it redraws itself while it is open - the sweep
// behind it is cached, so this costs a redraw and not a second scan.
private _existing = uiNamespace getVariable [QGVAR(scannerPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(scannerPFH), [{
    params ["", "_handle"];

    // TWO QUESTIONS, NOT ONE. "Is this app still open" decides whether the loop
    // lives; "is the pointer off it" decides whether it may REDRAW. They were
    // the same test, and redrawing means deleting and rebuilding every control
    // on the screen - so this loop was destroying the buttons under the
    // player's cursor once a second and a press had to survive a coin toss.
    // See EFUNC(tacpad,appIdle).
    if !(["scanner"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(scannerPFH), -1];
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    ["scanner"] call EFUNC(tacpad,openApp);
}, 2, []] call CBA_fnc_addPerFrameHandler];
