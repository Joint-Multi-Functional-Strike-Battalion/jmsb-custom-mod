#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO, the board (docs/DESIGN_VOICE.md, "Tablet RADIO app"): game voice
 * (VON) as nets and calls, never as frequencies.
 *
 *   NETS    MY NETS (left): net, VON channel, link, ear L / B / R, mute,
 *           state, who is talking. SOUNDS and KEYS (right).
 *   CALLS   the group adds and search over VON CHANNEL SLOTS and CONTACTS
 *           (left); the LIVE CALL with recent contacts, and CALLBACKS (right).
 *   MANAGE  leaders, RTO and admin only: the nets, their members, WHO CAN.
 *
 * READS, IT DOES NOT COMPUTE. Everything comes from jmfsb_voice's API, read
 * once here into the board's context and handed to each panel; every press
 * goes back through that API (or FUNC(radioDial), which is that API). With the
 * voice addon absent the board says so and draws nothing to press.
 *
 * UNDER TFAR OR ACRE (jmfsb_voice_system "tfar" / "acre", game voice off)
 * NETS shows that radio's nets from the same API (its own ear and volume);
 * CALLS and MANAGE say in words that calls are game voice only.
 *
 * Draws inside the tablet and on the vanilla map alike - EFUNC(tacpad,appFrame)
 * lays it in the host rectangle either way.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["radio", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([_display, "RADIO", PAGE_W, PAGE_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _voice = !isNil QEFUNC(voice,netState);
// GAME VOICE RUNS ONLY WITHOUT TFAR OR ACRE (user, 2026-10-20). Under them the
// voice API serves that radio's nets (jmfsb_voice_system); calls are VON only.
private _system = missionNamespace getVariable [QEGVAR(voice,system), VOICE_SYSTEM_VON];
private _otherRadio = _voice && {!(missionNamespace getVariable [QEGVAR(voice,active), true])};
private _systemName = toUpper _system;
private _me = call CBA_fnc_currentUnit;

// ONE READ OF THE API PER DRAW, shared by every panel, so two panels on one
// screen cannot show two different moments.
private _ctx = createHashMapFromArray [
    ["voice", _voice],
    ["system", _systemName],
    ["external", _otherRadio],
    ["rowH", _rowH],
    ["netState", [[], [] call EFUNC(voice,netState)] select _voice],
    ["nets", [[], [_me] call EFUNC(voice,nets)] select _voice],
    ["calls", [[], [] call EFUNC(voice,calls)] select _voice],
    ["slots", [[], [] call EFUNC(voice,callSlots)] select _voice],
    ["callbacks", [[], [] call EFUNC(voice,callbacks)] select _voice],
    ["contacts", [[], [] call EFUNC(voice,contacts)] select _voice],
    ["custom", [[], [] call FUNC(radioCustom)] select _voice],
    ["role", [] call FUNC(radioRole)]
];

private _tab = uiNamespace getVariable [QGVAR(radioTab), "nets"];
if ((RADIO_TABS findIf {(_x select 0) isEqualTo _tab}) < 0) then {_tab = "nets"};

private _note = switch (true) do {
    case (!_voice): {"NO VOICE ADDON LOADED - NOTHING TO READ"};
    case (_otherRadio): {format ["%1 IN USE - NETS FROM YOUR %1 RADIOS, NO CALLS", _systemName]};
    case (_tab isEqualTo "calls"): {format ["A CALL = ONE CUSTOM CHANNEL, UP TO %1", CALL_SIZE_MAX]};
    case (_tab isEqualTo "manage"): {"LEADERS, RTO, ADMIN ONLY"};
    default {"VON - MESH SETS EACH SPEAKER'S VOLUME"};
};
[_body, [_pad, _padY, _w - 2 * _pad, _rowH * 1.2], RADIO_TABS, _tab, QGVAR(radioTab), "radio", _note] call FUNC(appPageTabs);

private _top = _padY * 3 + _rowH * 1.2;
private _fullH = _h - _top - _padY;
private _fullW = _w - 2 * _pad;

if (!_voice) exitWith {
    [_body, [_pad, _top, _fullW, _rowH], "Game voice runs through the voice addon (jmfsb_voice), which this mission does not load.", ["dim"] call EFUNC(tacpad,theme), TEXT_TITLE] call EFUNC(tacpad,drawText);
};

// Calls are game voice (VON) only: under a radio mod CALLS and MANAGE say so.
if (_otherRadio && _tab isNotEqualTo "nets") exitWith {
    {
        [_body, [_pad, _top + _forEachIndex * _rowH * 1.4, _fullW, _rowH], _x, ["dim"] call EFUNC(tacpad,theme), TEXT_TITLE] call EFUNC(tacpad,drawText);
    } forEach [
        format ["This mission runs %1, so game voice (VON) is off.", _systemName],
        "Calls, contacts and callbacks are game voice only: there are none to show or make here.",
        format ["Talk on your %1 nets (the NETS tab and the net row), with %1's own keys.", _systemName]
    ];
};

switch (_tab) do {
    case "calls": {
        [_body, [_pad, _top, _fullW, _fullH], _ctx] call FUNC(appRadioCalls);
    };
    case "manage": {
        [_body, [_pad, _top, _fullW, _fullH], _ctx] call FUNC(appRadioManage);
    };
    default {
        private _leftW = (_w - 3 * _pad) * PAGE_SPLIT_RADIO;
        private _rightX = _pad * 2 + _leftW;
        [_body, [_pad, _top, _leftW, _fullH], _ctx] call FUNC(appRadioNets);
        if (_otherRadio) then {
            [_body, [_rightX, _top, _w - _rightX - _pad, _rowH], format ["Radio sounds and keys are %1's own.", _systemName], ["dim"] call EFUNC(tacpad,theme), TEXT_TITLE] call EFUNC(tacpad,drawText);
        } else {
            [_body, [_rightX, _top, _w - _rightX - _pad, _fullH], _ctx] call FUNC(appRadioSounds);
        };
    };
};

// LIVE: who is talking, the links and the calls move, so the board follows them
// - only when what it shows changed (FUNC(appRadioKey)), never under a press
// (EFUNC(tacpad,appIdle)) and never while the search box is being typed in. The
// voice events redraw it at once as well (XEH_postInit). The loop stands down
// when the app closes.
uiNamespace setVariable [QGVAR(radioSeen), [] call FUNC(appRadioKey)];

private _existing = uiNamespace getVariable [QGVAR(radioPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(radioPFH), [{
    params ["", "_handle"];

    if !(["radio"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(radioPFH), -1];
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    private _focus = focusedCtrl (HOST_DISPLAY);
    if (!isNull _focus && {ctrlType _focus isEqualTo CT_EDIT}) exitWith {};
    if (([] call FUNC(appRadioKey)) isEqualTo (uiNamespace getVariable [QGVAR(radioSeen), ""])) exitWith {};

    ["radio"] call EFUNC(tacpad,openApp);
}, RADIO_REFRESH, []] call CBA_fnc_addPerFrameHandler];
