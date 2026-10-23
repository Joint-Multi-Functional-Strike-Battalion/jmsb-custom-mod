#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO - CALLS, the right column: LIVE CALL over CALLBACKS.
 *
 * LIVE CALL. An incoming call rings here with ACCEPT and DECLINE - the walking
 * view's F1 / F4. The player's own call shows its slot, its clock, who is on
 * it, its priority and size, the RECENT contacts not on it (each a + button
 * that rings him in - FUNC(radioQuick)), HANG UP and MUTE CALL (mutes the call
 * net for the player). The last thing that happened to a call - a failure
 * reason, the priority warning, its end - is a line under it, off the voice
 * API's jmfsb_voice_callState (FUNC(radioCalls) keeps it in GVAR(radioLast)).
 * MAKE FLASH on a call already up is not built and has no button: the voice
 * API sets a call's priority only when it is dialled (CALLS' NEXT: FLASH).
 *
 * CALLBACKS. The requests the server holds for the player, either way round,
 * and how long each has waited (jmfsb_voice_fnc_callbacks). Both phones ring
 * when there is a route and a free slot; a request expires after 15 minutes.
 * CANCEL is not built and has no button: the voice API has no call to drop a
 * request.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Column rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioLive
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

_rect params ["_x0", "_y0", "_w0", "_h0"];
private _rowH = _ctx get "rowH";
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);

private _me = call CBA_fnc_currentUnit;
private _fnc_names = {
    params ["_units"];
    ((_units select {!isNull _x && _x isNotEqualTo _me}) apply {toUpper name _x}) joinString ", "
};
private _fnc_clock = {
    params ["_seconds"];
    private _s = floor (_seconds max 0);
    format ["%1:%2", floor (_s / SECONDS_PER_MINUTE), [_s mod SECONDS_PER_MINUTE, 2] call CBA_fnc_formatNumber]
};

private _liveH = (_h0 - _padY) * PAGE_SPLIT_RIGHT;
private _calls = _ctx get "calls";
private _ringing = _calls select {(_x param [1, ""]) isEqualTo CALL_RINGING};
private _mine = _calls select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};

([_body, [_x0, _y0, _w0, _liveH], "LIVE CALL", "CONFERENCE"] call FUNC(appPagePanel)) params ["_left", "_top", "_w"];
private _labelW = _w * 0.26;
private _valX = _left + _pad + _labelW;
private _valW = _w - _labelW - 2 * _pad;
private _y = _top + _padY;
private _btnH = _rowH * 1.3;

// Incoming first: a ring is the one thing on this page that will not wait.
{
    _x params ["_callId", "", ["_members", [], [[]]], ["_priority", CALL_ROUTINE, [""]]];
    [_body, [_left + _pad, _y, _w - 2 * _pad, _rowH], format ["INCOMING %1 from %2", _priority, [_members] call _fnc_names], _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    _y = _y + _rowH * 1.2;
    [_body, [_left + _pad, _y, _w * 0.3, _btnH], "ACCEPT F1", "fill", {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(pageData), ""]] call EFUNC(voice,callAccept);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _callId] call FUNC(appPageButton);
    [_body, [_left + _pad * 2 + _w * 0.3, _y, _w * 0.3, _btnH], "DECLINE F4", "alarm", {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(pageData), ""]] call EFUNC(voice,callDecline);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _callId] call FUNC(appPageButton);
    _y = _y + _btnH + _padY;
} forEach _ringing;

if (_mine isEqualTo []) then {
    if (_ringing isEqualTo []) then {
        [_body, [_left + _pad, _y, _w - 2 * _pad, _rowH], "No call. CALL a contact, or a group with the buttons above.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
    };
} else {
    (_mine select 0) params ["_callId", "_state", ["_members", [], [[]]], ["_priority", CALL_ROUTINE, [""]], ["_startedAt", CBA_missionTime, [0]]];
    private _slotIndex = (_ctx get "slots") findIf {(_x param [1, ""]) isEqualTo _callId};
    private _slot = 0;
    if (_slotIndex >= 0) then {_slot = ((_ctx get "slots") select _slotIndex) param [0, 0]};
    private _callName = ["CALL", format ["CALL %1", _slot]] select (_slot > 0);
    private _custom = ["", format ["  %1 Custom %2", MIDDOT_TEXT, _slot + count VON_FIXED_CUSTOM]] select (_slot > 0);
    private _when = [format ["  %1 DIALLING", MIDDOT_TEXT], format ["  %1 %2", MIDDOT_TEXT, [CBA_missionTime - _startedAt] call _fnc_clock]] select (_state isEqualTo CALL_LIVE);

    {
        _x params ["_label", "_value"];
        [_body, [_left + _pad, _y, _labelW, _rowH], _label, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
        [_body, [_valX, _y, _valW, _rowH], _value, _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
        _y = _y + _rowH * 1.2;
    } forEach [
        ["CALL", _callName + _custom + _when],
        ["ON CALL", [_members] call _fnc_names],
        ["PRIORITY", _priority],
        ["SIZE", format ["%1 / %2", count _members, CALL_SIZE_MAX]]
    ];

    // RECENT: the people the player last called, not on this one.
    private _recent = ([_members] call FUNC(radioQuick)) select [0, 3];
    if (_recent isNotEqualTo [] && {count _members < CALL_SIZE_MAX} && {[] call FUNC(radioCanAdd)}) then {
        [_body, [_left + _pad, _y, _labelW, _rowH], "RECENT", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
        _y = _y + _rowH * 1.1;
        private _chipW = (_w - 2 * _pad) / 3;
        {
            [_body, [_left + _pad + _forEachIndex * _chipW, _y, _chipW - _pad, _btnH], format ["+ %1", toUpper name _x], "line", {
                params ["_ctrl"];
                [[_ctrl getVariable [QGVAR(pageData), objNull]]] call FUNC(radioDial);
                {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
            }, _x] call FUNC(appPageButton);
        } forEach _recent;
        _y = _y + _btnH + _padY;
    };

    [_body, [_left + _pad, _y, _w * 0.3, _btnH], "HANG UP F4", "alarm", {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(pageData), ""]] call EFUNC(voice,hangUp);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _callId] call FUNC(appPageButton);

    // MUTE CALL: the call's net as the player hears it.
    private _callNets = (_ctx get "netState") select {(_x param [2, ""]) isEqualTo VOICE_KIND_CALL};
    if (_callNets isNotEqualTo []) then {
        (_callNets select 0) params ["_netId", "", "", "", ["_muteOn", false, [false]]];
        [_body, [_left + _pad * 2 + _w * 0.3, _y, _w * 0.3, _btnH], ["MUTE CALL", "UNMUTE CALL"] select _muteOn, "line", {
            params ["_ctrl"];
            (_ctrl getVariable [QGVAR(pageData), ["", false]]) call EFUNC(voice,setMute);
            {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, [_netId, !_muteOn]] call FUNC(appPageButton);
    };
    _y = _y + _btnH + _padY;
};

// THE LAST WORD ON A CALL, held a little: why a dial failed, the priority
// warning, the end - the voice API's own reasons, in words.
GVAR(radioLast) params [["_lastState", "", [""]], ["_lastAt", -1, [0]]];
private _lastWord = (createHashMapFromArray CALL_STATE_WORDS) getOrDefault [_lastState, ""];
if (_lastWord isNotEqualTo "" && {CBA_missionTime - _lastAt < CALL_STATE_HOLD}) then {
    [_body, [_left + _pad, _y, _w - 2 * _pad, _rowH], _lastWord, _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
};

// ---------------------------------------------------------- CALLBACKS ----
private _cbY = _y0 + _liveH + _padY;
private _callbacks = _ctx get "callbacks";
([_body, [_x0, _cbY, _w0, _h0 - _liveH - _padY], "CALLBACKS", format ["%1 PENDING", count _callbacks]] call FUNC(appPagePanel)) params ["_cl", "_ct", "_cw", "_ch"];

[_body, [_cl + _pad, _ct, _cw * 0.55, _rowH], "CALLBACK", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_cl + _cw * 0.58, _ct, _cw * 0.2, _rowH], "WAITING", _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_cl, _ct + _rowH, _cw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _step = _rowH * 1.5;
private _fits = floor ((_ch - _rowH * 3.5) / _step) max 1;
{
    _x params [["_from", objNull, [objNull]], ["_to", objNull, [objNull]], ["_at", CBA_missionTime, [0]], ["_state", "", [""]]];
    private _other = [_from, _to] select (_from isEqualTo _me);
    private _ry = _ct + _rowH * 1.2 + _forEachIndex * _step;
    private _cy = _ry + (_step - _rowH) * 0.5;
    private _who = if (isNull _other) then {"?"} else {toUpper name _other};
    [_body, [_cl + _pad, _cy, _cw * 0.55, _rowH], format ["%1 %2 %3", _who, MIDDOT_TEXT, toUpper _state], _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_cl + _cw * 0.58, _cy, _cw * 0.2, _rowH], [CBA_missionTime - _at] call _fnc_clock, _ink, TEXT_BODY] call EFUNC(tacpad,drawText);
    [_body, [_cl, _ry + _step - RULE_THIN * pixelH, _cw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach (_callbacks select [0, _fits]);

[
    _body, [_cl + _pad, _ct + _rowH * 1.2 + ((count _callbacks) min _fits) * _step + _rowH * 0.3, _cw - 2 * _pad, _rowH * 2],
    "Rings both phones when there is a route and a free slot. Expires after 15 min. Cancelling one is not built.",
    _muted, TEXT_LABEL
] call EFUNC(tacpad,drawText);
