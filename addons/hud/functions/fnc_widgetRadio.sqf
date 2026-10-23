#include "script_component.hpp"
/*
 * Author: JMSB
 * RADIO: the active voice net and what is happening on it - game voice (VON)
 * through jmfsb_voice's API (docs/DESIGN_VOICE.md). Never a frequency.
 *
 * IT DOES NOT IMPLEMENT A RADIO. It reads jmfsb_voice_fnc_netState: the active
 * net's name, TX while the player transmits on it (he is in the API's talking
 * list), NO ROUTE when the net is out of reach (never hidden), MUTED, the ear
 * the net's beeps pan to, and who is talking on it now. A call's state rides
 * on the second line - RINGING, CALL and its people. Without the voice addon
 * there is no net, and the tile says so rather than inventing one.
 *
 * THE JAMMING IS ON IT because a channel is only worth reading next to whether
 * anyone will hear it. That is the one number from the other tile that belongs
 * here.
 *
 * Arguments:
 * 0: The slot control <CONTROL>
 * 1: Y to start at <NUMBER>
 * 2: Slot width <NUMBER>
 * 3: Slot height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

// A call's states, as jmfsb_voice_fnc_calls names them.
#define WIDGET_CALL_RINGING "ringing"
#define WIDGET_CALL_LIVE "live"

params [["_ctrl", controlNull, [controlNull]], ["_y", 0, [0]], ["_w", 0, [0]], ["_h", 0, [0]]];

if (isNull _ctrl) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _base = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * safeZoneH;
// A ROW IS THE SUITE'S OWN ROW, AND IT ONLY EVER SHRINKS. Rows used to be the
// slot's whole box divided by however many of them there were, so a slot at its
// default size - the vanilla Custom Info panel's size - spread three lines down
// the whole panel with holes between them, at type twice the size the rest of
// the suite sets. The design's row height is the row height here too: a slot the
// player has made too SHORT for its rows squeezes them, and one made taller
// simply has air under the readout.
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / 3);
// Width caps the scale too - see the note in FUNC(widgetEw).
private _kw = (_w / (10 * (((safeZoneW / safeZoneH) min 1.2) / 40))) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _pad = PAD * safeZoneW;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _amber = [0.85, 0.65, 0.15, 1];

// THE NET, from the voice API: [netId, name, kind, active, muted, ear,
// reachable, talkers] per net the player is on; the active one is shown.
private _channel = "";
private _alternate = "";
private _link = "";
private _main = _ink;
private _linkColour = _mute;
if (!isNil QEFUNC(voice,netState)) then {
    private _nets = [] call EFUNC(voice,netState);
    private _i = _nets findIf {_x param [3, false]};
    if (_i >= 0) then {
        (_nets select _i) params ["_netId", ["_name", "", [""]], "", "", ["_muted", false, [false]], ["_ear", "", [""]], ["_reach", false, [false]], ["_talkers", [], [[]]]];
        _channel = toUpper _name;
        private _me = call CBA_fnc_currentUnit;
        // His own transmission: the voice API's talking list if it carries
        // him, else what the device layer kept off the voice talk event.
        private _tx = _netId isNotEqualTo "" && {(missionNamespace getVariable [QEGVAR(devices,talkSelf), ""]) isEqualTo _netId
            || {(([] call EFUNC(voice,talking)) findIf {(_x param [0, objNull]) isEqualTo _me && {(_x param [1, ""]) isEqualTo _netId}}) >= 0}};
        if (_tx) then {
            _channel = "TX  " + _channel;
            _main = _accent;
        };
        if (_muted) then {_main = _dim};
        _link = switch (true) do {
            case (!_reach): {"NO ROUTE"};
            case (_muted): {"MUTED"};
            default {["", "EAR " + _ear] select (_ear isNotEqualTo "")};
        };
        if (!_reach) then {_linkColour = _accent};
        private _who = (_talkers apply {_x param [0, objNull]}) select {!isNull _x && _x isNotEqualTo _me};
        if (_who isNotEqualTo []) then {_alternate = toUpper ((_who apply {name _x}) joinString ", ")};
    };
    // A call outranks who is talking on the second line.
    private _calls = [] call EFUNC(voice,calls);
    private _ring = _calls findIf {(_x param [1, ""]) isEqualTo WIDGET_CALL_RINGING};
    private _live = _calls findIf {(_x param [1, ""]) isEqualTo WIDGET_CALL_LIVE};
    if (_ring >= 0) then {_alternate = "CALL RINGING"};
    if (_ring < 0 && _live >= 0) then {_alternate = format ["CALL %1 ON", count ((_calls select _live) param [2, []])]};
};

if (_channel isEqualTo "") exitWith {
    [_ctrl, [_pad, _y, _w - 2 * _pad, _rowH], (switch (true) do {case (isNil QEFUNC(voice,netState)): {"NO VOICE ADDON"}; case !(missionNamespace getVariable [QEGVAR(voice,active), true]): {format ["%1: NO NET", toUpper (missionNamespace getVariable [QEGVAR(voice,system), ""])]}; default {"NO VOICE NET"}}), _dim, (0.85 * _k), true] call EFUNC(tacpad,drawText);
};

// The link reading takes the right quarter of the line; the net the rest.
private _nameW = [_w - 2 * _pad, _w * 0.75 - _pad] select (_link isNotEqualTo "");
[_ctrl, [_pad, _y, _nameW, _rowH * 1.4], _channel, _main, (1.3 * _k), true] call EFUNC(tacpad,drawText);
if (_link isNotEqualTo "") then {
    [_ctrl, [_w * 0.75, _y, _w * 0.25 - _pad, _rowH * 1.4], _link, _linkColour, (0.8 * _k), true, "right"] call EFUNC(tacpad,drawText);
};
if (_alternate isNotEqualTo "") then {
    [_ctrl, [_pad, _y + _rowH * 1.6, _w * 0.6, _rowH], _alternate, _mute, (0.62 * _k), true, "left", true] call EFUNC(tacpad,drawText);
};

private _sweep = [] call FUNC(sweep);
if (_sweep isEqualTo []) exitWith {};

_sweep params ["", "", "", ["_jam", 0]];
private _pct = round (_jam * 100);

private _colour = switch (true) do {
    case (_pct >= 50): {_accent};
    case (_pct > 0): {_amber};
    default {_ink};
};

// JAM sits right; on its own when there is no alternate net on the left.
if (_alternate isEqualTo "") then {
    [_ctrl, [_pad, _y + _rowH * 1.6, _w * 0.5, _rowH], "JAM", _mute, (0.62 * _k), true, "left", true] call EFUNC(tacpad,drawText);
};
[
    _ctrl, [_w * 0.5, _y + _rowH * 1.6, _w * 0.5 - _pad, _rowH],
    format ["%1%2%3", ["JAM ", ""] select (_alternate isEqualTo ""), _pct, "%"], _colour, (0.9 * _k), true, "right"
] call EFUNC(tacpad,drawText);
