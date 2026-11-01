#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO - NETS, the MY NETS panel (docs/DESIGN_VOICE.md, "Tablet RADIO app"):
 * one row per net the player is on - only those (VEH inside a vehicle, CALL
 * while a call is live or ringing; a captured key's net is not built) - with
 * the VON channel it rides on, the link, the ear (L / B / R), mute, the state
 * and who is talking on it now.
 *
 * Pressing a net's name makes it the active net (the one numpad 0 / . step
 * through). A net out of reach is not hidden: its state says NO ROUTE and its
 * link is empty. LINK is RF's quality for the net when RF knows it, else the
 * best quality of whoever is talking on it, else just whether it is reachable.
 * EAR pans the net's beeps and static, not the voice - VON cannot pan voice.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appRadio)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appRadioNets
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";
private _netsOn = (_ctx get "netState") select {(_x param [2, ""]) isNotEqualTo VOICE_KIND_DIRECT};
private _channels = _ctx get "nets";

([_body, _rect, "MY NETS", "GAME VOICE (VON)"] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _tint = ["accentTint"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;

if (_netsOn isEqualTo []) exitWith {
    [_body, [_left + _pad, _top + _rowH * 0.5, _w - 2 * _pad, _rowH], "You are on no voice net.", _dim, TEXT_TITLE] call EFUNC(tacpad,drawText);
};

// Column starts as shares of the panel.
private _cols = [0, 0.05, 0.19, 0.31, 0.45, 0.59, 0.67, 0.75, 0.86];
private _heads = ["#", "NET", "VON", "LINK", "EAR", "MUTE", "PTT", "STATE", "TALKING"];
private _cx = _cols apply {_left + _pad + _x * (_w - 2 * _pad)};
private _cw = [];
{
    _cw pushBack ((_cx param [_forEachIndex + 1, _left + _w - _pad]) - _x - _pad * 0.5);
} forEach _cx;

{
    [_body, [_x, _top, _cw select _forEachIndex, _rowH], _heads select _forEachIndex, _muted, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
} forEach _cx;

private _y = _top + _rowH;
[_body, [_left, _y, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _rowStep = _rowH * 1.4;
{
    _x params [["_netId", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], ["_active", false, [false]], ["_mute", false, [false]], ["_ear", "B", [""]], ["_reach", false, [false]], ["_talkers", [], [[]]]];
    private _ry = _y + _forEachIndex * _rowStep;
    private _cy = _ry + (_rowStep - _rowH) * 0.5;

    if (_active) then {
        [_body, [_left, _ry, _w, _rowStep], _tint] call EFUNC(tacpad,drawFill);
    };

    [_body, [_cx select 0, _cy, _cw select 0, _rowH], str (_forEachIndex + 1), _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);

    // The name is the SET ACTIVE button.
    [_body, [_cx select 1, _cy, _cw select 1, _rowH], toUpper _name, ([_ink, _dim] select _mute), TEXT_BODY, true] call EFUNC(tacpad,drawText);
    private _hit = [_body, [_cx select 1, _ry, _cw select 1, _rowStep], {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(pageData), ""]] call EFUNC(voice,setActive);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(pageData), _netId];

    [_body, [_cx select 2, _cy, _cw select 2, _rowH], [_netId, _channels] call FUNC(radioVon), _ink, TEXT_BODY] call EFUNC(tacpad,drawText);

    // LINK: RF's word on the net, else the talkers', else reach alone.
    private _q = [_netId] call FUNC(radioRfQuality);
    if (_q < 0 && {_talkers isNotEqualTo []}) then {
        {_q = _q max (_x param [1, 0])} forEach _talkers;
    };
    if (!_reach) then {_q = 0};
    private _said = switch (true) do {
        case (!_reach): {"NO ROUTE"};
        case (_q < 0): {"OK"};
        default {""};
    };
    [_body, [_cx select 3, _cy, _cw select 3, _rowH], _q, _said] call FUNC(appPageBar);

    // EAR: three segments, the net's own picked.
    private _segW = (_cw select 4) / count RADIO_EARS;
    {
        private _style = ["line", "fill"] select (_x isEqualTo _ear);
        [_body, [(_cx select 4) + _forEachIndex * _segW, _cy, _segW - _pad * 0.5, _rowH], _x, _style, {
            params ["_ctrl"];
            (_ctrl getVariable [QGVAR(pageData), ["", ""]]) call EFUNC(voice,setEar);
            {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, [_netId, _x]] call FUNC(appPageButton);
    } forEach RADIO_EARS;

    [_body, [_cx select 5, _cy, (_cw select 5) - _pad * 0.5, _rowH], ["MUTE", "MUTED"] select _mute, ["line", "alarm"] select _mute, {
        params ["_ctrl"];
        (_ctrl getVariable [QGVAR(pageData), ["", false]]) call EFUNC(voice,setMute);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, [_netId, !_mute]] call FUNC(appPageButton);

    // PTT (user, 2026-10-30): PTT 1 is always the active net; a press steps
    // the net through PTT 2, 3, 4 and none (jmfsb_voice_fnc_pttKey).
    if (_active) then {
        [_body, [_cx select 6, _cy, _cw select 6, _rowH], "PTT 1", _dim, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    } else {
        private _ptt = [_netId] call EFUNC(voice,pttKey);
        [_body, [_cx select 6, _cy, (_cw select 6) - _pad * 0.5, _rowH], ["PTT", format ["PTT %1", _ptt]] select (_ptt > 0), ["line", "fill"] select (_ptt > 0), {
            params ["_ctrl"];
            [_ctrl getVariable [QGVAR(pageData), ""], true] call EFUNC(voice,pttKey);
            {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }, _netId] call FUNC(appPageButton);
    };

    private _state = switch (true) do {
        case (!_reach): {"NO ROUTE"};
        case (_kind isEqualTo VOICE_KIND_CALL): {"LIVE"};
        case (_active): {"ACTIVE"};
        case (_mute): {"MUTED"};
        default {"MON"};
    };
    [_body, [_cx select 7, _cy, _cw select 7, _rowH], _state, ([_ink, _accent] select (_active || !_reach)), TEXT_BODY, true] call EFUNC(tacpad,drawText);

    private _who = (_talkers apply {_x param [0, objNull]}) select {!isNull _x} apply {toUpper name _x};
    if (_who isNotEqualTo []) then {
        [_body, [_cx select 8, _cy, _cw select 8, _rowH], _who joinString ", ", _accent, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    };

    [_body, [_left, _ry + _rowStep - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _netsOn;

private _footY = _y + (count _netsOn) * _rowStep + _rowH * 0.5;

// THE BATTERY (user, 2026-10-30): the handheld's charge, and SWAP BATTERY,
// which spends a spare from the kit (jmfsb_voice_fnc_batterySwap).
private _level = [] call EFUNC(voice,batteryLevel);
if (_level >= 0) then {
    private _spares = count ([] call EFUNC(voice,batterySpares));
    private _low = _level <= RADIO_BATTERY_LOW;
    [_body, [_left + _pad, _footY, (_cx select 4) - _left - _pad, _rowH], format ["BATTERY %1%2%3", round (_level * PERCENT), "%", ["", " - LOW"] select _low], [_ink, _accent] select _low, TEXT_BODY, true] call EFUNC(tacpad,drawText);
    [_body, [_cx select 4, _footY, (_cx select 7) - (_cx select 4) - _pad * 0.5, _rowH], format ["SWAP BATTERY (%1 SPARE)", _spares], ["line", "alarm"] select _low, {
        [] call EFUNC(voice,batterySwap);
        {["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, ""] call FUNC(appPageButton);
    _footY = _footY + _rowStep;
};

{
    [_body, [_left + _pad, _footY + _forEachIndex * _rowH, _w - 2 * _pad, _rowH], _x, _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
} forEach [
    "Only nets you are on are shown. Press a net's name, or numpad 0 / . anywhere, to pick the active net.",
    "VEH appears in a vehicle, CALL while a call is live or ringing. The ear pans the beeps and static, not the voice (VON).",
    "PTT 1 (Caps Lock) is the active net. PTT 2-4 talk on the net you give them here; bind each key in Configure Addons and under Arma's Push To Talk too."
];
