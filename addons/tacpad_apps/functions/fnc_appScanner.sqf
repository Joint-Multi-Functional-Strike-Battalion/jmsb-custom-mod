#include "script_component.hpp"
/*
 * Author: YonV
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
 * BUILT ONCE, TICKED IN PLACE (code review R8). The headline, the readings and
 * the alerts are FUNC(scannerLive)'s values, drawn here in the order they
 * come; the page's tick writes the next values into the same lines
 * (EFUNC(tacpad,liveApply)) and builds the page again only when its shape has
 * changed.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_tacpad_apps_fnc_appScanner
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
([_display, "EW SCANNER", 0.46, 0.56] call EFUNC(tacpad,appFrame)) params ["_group", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];
private _dim = [_ink # 0, _ink # 1, _ink # 2, LIVE_DIM_ALPHA];

// THE LIVE LINES. The nth live line drawn takes the nth value, and is kept
// with its type role for the tick to write the next one into.
([] call FUNC(scannerLive)) params ["_shape", "_values", "_labels", "_alertCount"];
private _entries = [];
private _fnc_live = {
    params ["_rect", "_size", ["_bold", false], ["_align", "left"], ["_tracked", false]];
    (_values select (count _entries)) params ["_text", "_colour"];
    private _ctrl = [_body, _rect, _text, _colour, _size, _bold, _align, _tracked] call EFUNC(tacpad,drawText);
    _entries pushBack [[_ctrl], [_size, _bold, _align, _tracked, ""]];
    _ctrl
};

// A DENIED SCANNER IS A STATE, NOT AN EMPTY PAGE. A mission can take the
// receiver off a man, and a page of dashes does not say that anybody did.
if !([player] call EFUNC(hacking,hasScanner)) exitWith {
    [_body, [_pad, _padY, _w - 2 * _pad, _rowH], "NO RECEIVER", _accent, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    [
        _body, [_pad, _padY + _rowH * 1.2, _w - 2 * _pad, _rowH],
        "This unit is not carrying a spectrum receiver.", _mute, TEXT_TITLE
    ] call EFUNC(tacpad,drawText);
    [_group, _shape, _entries] call EFUNC(tacpad,liveStore);
};

// ------------------------------------------------------------- the hero -----
// The worst thing the sweep found, in one word. A scanner's first answer is
// whether to care at all.
private _heroH = _rowH * 2.2;
[[_pad, _padY, _w - 2 * _pad, _heroH * 0.7], TEXT_DISPLAY, true] call _fnc_live;
// The sub-line was your channel - radio information, which is the RADIO
// app's. The sweep page speaks spectrum only now.

private _y = _padY + _heroH;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// ------------------------------------------------------------- the rows -----
// The readings, label and value (FUNC(scannerLive)).
{
    private _ry = _y + _forEachIndex * _rowH;

    [_body, [_pad, _ry, _w * 0.34, _rowH], _x, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [[_w * 0.36, _ry, _w * 0.64 - _pad, _rowH], TEXT_TITLE, true, "right"] call _fnc_live;
    [_body, [_pad, _ry + _rowH - RULE_THIN * pixelH, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _labels;

_y = _y + (count _labels) * _rowH + _padY;

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

if (_alertCount isEqualTo 0) then {
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NOTHING IN THE LAST FEW MINUTES", _dim, TEXT_TITLE] call EFUNC(tacpad,drawText);
} else {
    for "_i" from 0 to (_alertCount - 1) do {
        private _ay = _y + _i * _rowH;
        [[_pad, _ay, _w * 0.2, _rowH], TEXT_LABEL, true, "left", true] call _fnc_live;
        [[_w * 0.22, _ay, _w * 0.78 - _pad, _rowH], TEXT_BODY] call _fnc_live;
    };
};

[_group, _shape, _entries] call EFUNC(tacpad,liveStore);

// The page's tick: the next values in place, or the page again when its shape
// has changed and the pointer is off it (EFUNC(tacpad,appIdle) - a rebuild
// deletes every control, and a control deleted between the press and the
// release never raises a click). It is a live readout, and the sweep behind
// it is cached, so this costs a few words and not a second scan.
private _existing = uiNamespace getVariable [QGVAR(scannerPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(scannerPFH), [{
    params ["", "_handle"];

    if !(["scanner"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(scannerPFH), -1];
    };

    ([] call FUNC(scannerLive)) params ["_shape", "_values"];
    if ([uiNamespace getVariable [QEGVAR(tacpad,appGroup), controlNull], _shape, _values] call EFUNC(tacpad,liveApply)) exitWith {};

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    ["scanner"] call EFUNC(tacpad,openApp);
}, 2, []] call CBA_fnc_addPerFrameHandler];
