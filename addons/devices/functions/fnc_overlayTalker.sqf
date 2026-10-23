#include "script_component.hpp"
/*
 * Author: JMSB
 * The talking box (docs/DESIGN_VOICE.md, "Nets on the devices": name, net and
 * ear): "<N> <NAME> on <NET> [EAR]" for the last man heard, held for TALK_HOLD
 * seconds after he stops - or, while a call rings, "RINGING <NAME>". On a call
 * net it reads "<NAME> on CALL - <n> on [EAR]".
 *
 * Read from FUNC(voiceTalkers) (the voice API's own talking list); a radio
 * speaker wins over a direct one when two talk at once. Remembers the last
 * speaker in GVAR(overlayTalker) - [unit, voice, time, net id] - so the box
 * outlives the talking by the hold.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Structured text for the box, "" when nobody has talked lately <STRING>
 *
 * Example:
 * private _chip = [] call jmfsb_devices_fnc_overlayTalker
 *
 * Public: No
 */

private _unit = call CBA_fnc_currentUnit;
if (isNull _unit || {isNull group _unit} || {isNil QEFUNC(voice,netState)}) exitWith {""};

// A ring outranks a voice: it is the one thing that will not wait.
private _calls = [] call EFUNC(voice,calls);
private _ring = _calls select {(_x param [1, ""]) isEqualTo CALL_RINGING};
if (_ring isNotEqualTo []) exitWith {
    private _from = ((_ring select 0) param [2, []]) select {!isNull _x && _x isNotEqualTo _unit};
    format [
        "<t color='%1'>%2</t> <t color='%3'>RINGING</t> <t color='%4'>%5</t>",
        HTML_TX, DOT_TEXT, HTML_TEXT, HTML_DIM,
        [toUpper ((_from apply {name _x}) joinString ", ")] call EFUNC(tacpad,xmlSafe)
    ]
};

private _best = objNull;
private _bestVoice = 0;
private _bestNet = "";
{
    _y params [["_man", objNull, [objNull]], ["_v", 0, [0]], ["_net", "", [""]]];
    if (!isNull _man && _v > _bestVoice) then {
        _best = _man;
        _bestVoice = _v;
        _bestNet = _net;
    };
} forEach ([] call FUNC(voiceTalkers));

if (!isNull _best) then {
    GVAR(overlayTalker) = [_best, _bestVoice, time, _bestNet];
};

GVAR(overlayTalker) params [["_who", objNull, [objNull]], ["_how", 0, [0]], ["_at", 0, [0]], ["_netId", "", [""]]];
if (isNull _who || {time - _at > TALK_HOLD}) exitWith {""};

private _number = if (isNil QEFUNC(bft,memberNumber)) then {
    ((units group _who) find _who) + 1
} else {
    [_who] call EFUNC(bft,memberNumber)
};

// The net as the player has it: its name, ear and kind.
private _state = [] call EFUNC(voice,netState);
private _i = _state findIf {(_x param [0, ""]) isEqualTo _netId};
(_state param [_i max 0, []]) params [["_id", "", [""]], ["_name", "", [""]], ["_kind", "", [""]], "", "", ["_ear", "", [""]]];
if (_i < 0 || _id isNotEqualTo _netId) then {
    _name = "";
    _ear = "";
};

private _onCall = "";
if (_kind isEqualTo VOICE_KIND_CALL) then {
    private _live = _calls select {(_x param [1, ""]) isEqualTo CALL_LIVE};
    _onCall = format [" %1 %2 on", MIDDOT, count ((_live param [0, []]) param [2, []])];
};

private _where = switch (true) do {
    case (_how isEqualTo VOICE_DIRECT): {"VOX"};
    case (_name isEqualTo ""): {"radio"};
    default {toUpper _name};
};

format [
    "<t color='%1'>%2</t> <t color='%3'>%4 %5</t> <t color='%6'>on</t> <t color='%3'>%7</t><t color='%6'>%8</t>%9",
    [HTML_OK, HTML_TX] select (_kind isNotEqualTo VOICE_KIND_CALL),
    DOT_TEXT,
    HTML_TEXT,
    _number,
    [toUpper name _who] call EFUNC(tacpad,xmlSafe),
    HTML_DIM,
    [_where] call EFUNC(tacpad,xmlSafe),
    _onCall,
    ["", format [" <t color='%1'>[%2]</t>", HTML_DIM, _ear]] select (_ear isNotEqualTo "")
]
