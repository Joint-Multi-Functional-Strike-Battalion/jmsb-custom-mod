#include "script_component.hpp"
/*
 * Author: JMSB
 * JAMMING, full size: how much of the spectrum is being sat on. NOTHING ELSE.
 * Drones and jamming are two different things and their pages must not look
 * alike - the user's rule, in those words. Drones have their own page
 * (FUNC(appDrones)); channel, frequency, mesh and net state are the RADIO
 * app's; the whole sweep at once is the EW SCANNER.
 *
 * WITH THE EW ADDON IT IS THE JAMMER'S CONTROL PANEL (user, 2026-10-21: "I
 * was hoping for an RF page like this"): the same panel as TAC//EW's EA tab
 * (jmfsb_ew_fnc_appEa) - his jammer's switch and settings, the spectrum where
 * he stands, what the side hears, and how jammed he is here - on this app's
 * own frame, redrawn when his EW slice or the scanner's figures change. The
 * page below is what is left without the EW addon.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

if (!isNil QEFUNC(ew,appEa)) exitWith {
    ([_display, "JAMMER CONTROL", JAMMER_PANEL_W, JAMMER_PANEL_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
    if (isNull _body) exitWith {};

    // What this draw is OF: his slice and, with a scanner, how jammed he is.
    private _fnc_seen = {
        private _here = if (isNil QEFUNC(hacking,scannerRead)) then {[]} else {([] call EFUNC(hacking,scannerRead)) select [JAM_READ_FROM, JAM_READ_COUNT]};
        str [EGVAR(ew,mine), _here, (missionNamespace getVariable [QEGVAR(common,alerts), []]) select {(_x param [4, 0]) > CBA_missionTime}]
    };

    if (EGVAR(ew,mine) isEqualTo []) then {
        ([] call EFUNC(tacpad,theme)) params ["", "_ink", "_accent"];
        private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
        [_body, [PAD * HOST_W, PAD * HOST_H, (ctrlPosition _body) # 2, _rowH], "NO EW PICTURE YET - EW NEEDS THE RF CORE RUNNING", _accent, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    } else {
        [_body, PAD * HOST_H] call EFUNC(ew,appEa);
    };
    uiNamespace setVariable [QGVAR(jamSeen), call _fnc_seen];

    private _existing = uiNamespace getVariable [QGVAR(jamPFH), -1];
    if (_existing >= 0) then {
        [_existing] call CBA_fnc_removePerFrameHandler;
    };
    uiNamespace setVariable [QGVAR(jamPFH), [{
        params ["_fnc_seen", "_handle"];
        if !(["jam"] call EFUNC(tacpad,appAlive)) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
            uiNamespace setVariable [QGVAR(jamPFH), -1];
        };
        if !([] call EFUNC(tacpad,appIdle)) exitWith {};
        if ((call _fnc_seen) isEqualTo (uiNamespace getVariable [QGVAR(jamSeen), ""])) exitWith {};
        ["jam"] call EFUNC(tacpad,openApp);
    }, 2, _fnc_seen] call CBA_fnc_addPerFrameHandler];
};

if (isNil QEFUNC(hacking,scannerRead)) exitWith {
    ["JAMMING", "The intrusion suite is not loaded.", "high"] call EFUNC(messaging,notify);
};

([_display, "JAMMING", 0.36, 0.46] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _amber = [0.85, 0.65, 0.15, 1];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

if !([player] call EFUNC(hacking,hasScanner)) exitWith {
    [_body, [_pad, _padY, _w - 2 * _pad, _rowH], "NO RECEIVER", _accent, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
};

([] call EFUNC(hacking,scannerRead)) params ["", "", "", ["_jam", 0], "", "", "", "",
    ["_jamRadio", 0], ["_jamData", 0], ["_jamGps", 0]];

// Older scannerRead builds had no per-domain figures; fall back to the
// aggregate on RADIO, which is what the single bar always meant.
if (_jamRadio + _jamData + _jamGps <= 0 && _jam > 0) then { _jamRadio = _jam };

// THE HEADLINE IS STILL ONE NUMBER, and it is the WORST of the three - the
// page has to answer "how bad is it here" before it answers "at what". It is
// NAMED, because "0%" standing beside a status word read as "0% usable", which
// is backwards: the number is how much of the spectrum is being JAMMED, and
// zero jammed is a good day.
private _pct = round (_jam * 100);
private _state = 0;
if (_pct > 0) then {_state = 1};
if (_pct >= 75) then {_state = 2};
private _colour = [_ink, _amber, _accent] select _state;

[
    _body, [_pad, _padY, _w - 2 * _pad, _rowH * 1.8],
    format ["%1%2 JAMMED", _pct, "%"], _colour, TEXT_DISPLAY, true
] call EFUNC(tacpad,drawText);

// THEN WHICH SERVICE, one row each (user, 2026-08-31). The headline says how
// dirty the air is; these say what you have actually lost, which is the part
// that decides whether you key up, send a report, or trust the map.
private _rowY = _padY + _rowH * 2.1;
{
    _x params ["_name", "_f"];

    private _p = round (_f * 100);
    private _s = switch (true) do {
        case (_p >= 75): {2};
        case (_p > 0): {1};
        default {0};
    };
    private _c = [_ink, _amber, _accent] select _s;
    private _top = _rowY + _rowH * 1.15 * _forEachIndex;

    [
        _body, [_pad, _top, (_w - 2 * _pad) * 0.42, _rowH],
        format ["%1 %2", _name, ["OK", "DEGRADED", "NONET"] select _s],
        _c, TEXT_TITLE, true, "left", true
    ] call EFUNC(tacpad,drawText);

    private _barX = _pad + (_w - 2 * _pad) * 0.46;
    private _barW = (_w - _pad - _barX) max 0;
    [_body, [_barX, _top + _rowH * 0.3, _barW, _rowH * 0.4], _line] call EFUNC(tacpad,drawFill);
    if (_p > 0) then {
        [_body, [_barX, _top + _rowH * 0.3, _barW * (_p / 100), _rowH * 0.4], _c] call EFUNC(tacpad,drawFill);
    };
} forEach [["RADIO", _jamRadio], ["DATA", _jamData], ["GPS", _jamGps]];

private _barY = _rowY + _rowH * 1.15 * 3;

// WHAT HAS BEEN DONE TO US LATELY - carried over from the cTab jam page,
// which the new page had dropped and the user missed: every jmfsb system
// that fires, flies or shells at players posts to one bus, and this reads
// the last two minutes of it back.
private _y = _barY + _rowH * 1.8;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_y = _y + _padY;
[_body, [_pad, _y, _w - 2 * _pad, _rowH], "RECENT ALERTS", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
_y = _y + _rowH;

private _alerts = (missionNamespace getVariable [QEGVAR(common,alerts), []]) select {(_x param [4, 0]) > CBA_missionTime};

// What this draw is OF - see the drone page's loop note. ALL FOUR figures,
// in the same shape the refresh gate below builds: storing only the headline
// while the gate compared four would never match, and the page would have
// redrawn itself every two seconds for the rest of the mission.
uiNamespace setVariable [QGVAR(jamSeen),
    str [([_jam, _jamRadio, _jamData, _jamGps] apply { round (_x * 100) }), _alerts]];

if (_alerts isEqualTo []) then {
    private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], "NOTHING IN THE LAST FEW MINUTES", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
} else {
    {
        _x params ["_src", "_txt", "_grid", ["_sev", 0]];
        private _ay = _y + _forEachIndex * _rowH;

        [_body, [_pad, _ay, _w * 0.22, _rowH], toUpper _src, ([_mute, _amber, _accent] select (_sev min 2)), TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
        [
            _body, [_w * 0.24, _ay, _w * 0.76 - _pad, _rowH],
            [_txt, format ["%1 - %2", _txt, _grid]] select (_grid isNotEqualTo ""),
            _ink, TEXT_BODY
        ] call EFUNC(tacpad,drawText);
        if (_forEachIndex >= 5) exitWith {};
    } forEach _alerts;
};

// Live page - the drone page's own loop pattern.
private _existing = uiNamespace getVariable [QGVAR(jamPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(jamPFH), [{
    params ["", "_handle"];

    if !(["jam"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(jamPFH), -1];
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};

    // Redraw ONLY when the picture changed - the drone page's rule.
    // The WHOLE picture, not just the aggregate: a hub coming up denies data
    // without moving index 3 if a radio field already covers this spot, and
    // the page would have sat there showing the old rows.
    ([] call EFUNC(hacking,scannerRead)) params ["", "", "", ["_jam", 0], "", "", "", "",
        ["_jr", 0], ["_jd", 0], ["_jg", 0]];
    private _jam = [_jam, _jr, _jd, _jg] apply { round (_x * 100) };
    private _alerts = (missionNamespace getVariable [QEGVAR(common,alerts), []]) select {(_x param [4, 0]) > CBA_missionTime};
    if ((str [_jam, _alerts]) isEqualTo (uiNamespace getVariable [QGVAR(jamSeen), ""])) exitWith {};

    ["jam"] call EFUNC(tacpad,openApp);
}, 2, []] call CBA_fnc_addPerFrameHandler];
