#include "script_component.hpp"
/*
 * Author: JMSB
 * HACK, the board (docs/DESIGN_TABLET_APPS.md, HACK): NODES IN REACH down the
 * left, the ACTION on the selected one top right, and the LOG of the current
 * hack under it.
 *
 * IT DOES NOT REIMPLEMENT THE SUITE. Scanning, selection, ranges, cooldowns,
 * the progress clock and what a completed hack yields are all jmfsb_hacking's
 * - this calls scanDevices (through tabletAdvance), tabletSelectDevice,
 * tabletSelectIntel and tabletAction and draws the result. What it adds is
 * RF: the board asks the server, while it is open, which RF nodes the player's
 * set can hear (jmfsb_hacking_fnc_rfReach through RF's nodesFor and budget),
 * and NODES IN REACH carries that quality beside the suite's own range.
 *
 * Draws inside the tablet and on the vanilla map alike (EFUNC(tacpad,appFrame)).
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["hack", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

if (isNil QEFUNC(hacking,tabletAction)) exitWith {
    ["HACK", "The intrusion suite is not loaded.", "high"] call EFUNC(messaging,notify);
};

// Say why, rather than opening a screen that can do nothing. The gate is the
// mission's ISR flag and jmfsb deliberately never writes it - see
// jmfsb_common_fnc_isISR.
if !([player] call EFUNC(hacking,canHack)) exitWith {
    ["HACK", "You are not cleared to use the intrusion suite.", "high"] call EFUNC(messaging,notify);
};

([_display, "HACK", PAGE_W, PAGE_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

// SCAN BEFORE DRAWING THE FIRST FRAME - an app that opens on NOTHING IN RANGE
// and corrects itself a second later has already said it is broken.
call EFUNC(hacking,tabletAdvance);
[] call FUNC(appHackTrack);

// THE FIRST ASK FOR RF goes out with the first frame; the loop repeats it.
if (CBA_missionTime - (uiNamespace getVariable [QGVAR(hackAsked), -HACKAPP_RF_ASK]) >= HACKAPP_RF_ASK) then {
    uiNamespace setVariable [QGVAR(hackAsked), CBA_missionTime];
    [QEGVAR(hacking,rfReachAsk), [player]] call CBA_fnc_serverEvent;
};

private _ctx = createHashMapFromArray [
    ["rows", [] call FUNC(appHackNodes)],
    ["session", EGVAR(hacking,session)],
    ["rowH", _rowH]
];

private _rfAge = CBA_missionTime - (missionNamespace getVariable [QEGVAR(hacking,rfReachTime), -1]);
private _note = if (isNil QEFUNC(rf,budget)) then {"RF NOT LOADED - SUITE RANGES ONLY"} else {
    if ((missionNamespace getVariable [QEGVAR(hacking,rfReachTime), -1]) < 0) then {"ASKING RF"} else {
        format ["RF %1 S AGO - AI AND PLAYERS CAN BOTH BE TARGETS", round _rfAge]
    }
};
[_body, [_pad, _padY, _w - 2 * _pad, _rowH * 1.2], [["nodes", "NODES"]], "nodes", QGVAR(hackTab), "hack", _note] call FUNC(appPageTabs);

private _top = _padY * 3 + _rowH * 1.2;
private _fullH = _h - _top - _padY;
private _leftW = (_w - 3 * _pad) * PAGE_SPLIT_HACK;
private _rightX = _pad * 2 + _leftW;
private _rightW = _w - _rightX - _pad;
private _actH = (_fullH - _padY) * PAGE_SPLIT_RIGHT;

[_body, [_pad, _top, _leftW, _fullH], _ctx] call FUNC(appHackList);
[_body, [_rightX, _top, _rightW, _actH], _ctx] call FUNC(appHackAction);
[_body, [_rightX, _top + _actH + _padY, _rightW, _fullH - _actH - _padY], _ctx] call FUNC(appHackLog);

// A hack runs on a clock, so the board keeps up with it - the suite's clock
// advances every tick, the LOG notes what changed, RF is asked again every
// HACKAPP_RF_ASK, and the redraw waits while the pointer is on the board (see
// EFUNC(tacpad,appIdle)). The loop goes with the app.
private _existing = uiNamespace getVariable [QGVAR(hackPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(hackPFH), [{
    params ["", "_handle"];

    if !(["hack"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(hackPFH), -1];
    };

    // The hack advances whether or not the screen is redrawn - the clock is
    // the mission's, not the display's.
    call EFUNC(hacking,tabletAdvance);
    [] call FUNC(appHackTrack);

    if (CBA_missionTime - (uiNamespace getVariable [QGVAR(hackAsked), -HACKAPP_RF_ASK]) >= HACKAPP_RF_ASK) then {
        uiNamespace setVariable [QGVAR(hackAsked), CBA_missionTime];
        [QEGVAR(hacking,rfReachAsk), [player]] call CBA_fnc_serverEvent;
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    ["hack"] call EFUNC(tacpad,openApp);
}, HACKAPP_REFRESH, []] call CBA_fnc_addPerFrameHandler];
