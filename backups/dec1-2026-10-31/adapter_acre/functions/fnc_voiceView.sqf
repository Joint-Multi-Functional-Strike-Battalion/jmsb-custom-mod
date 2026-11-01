#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: this player's ACRE radios as the voice API sees them (jmfsb_voice
 * reads these through its hooks, addons/voice/README.md):
 *
 *   GVAR(nets)    [[net, name, kind, -1], ...] - the net of each radio he
 *                 carries (fnc_radioNet), each once;
 *   GVAR(rows)    [[net, name, kind, active, muted, ear, reachable], ...] -
 *                 active = the radio in hand (acre_api_fnc_getCurrentRadio),
 *                 muted = its volume is 0 (acre_api_fnc_getRadioVolume), ear =
 *                 its spatial zone (acre_api_fnc_getRadioSpatial), reachable =
 *                 it is on (acre_api_fnc_getRadioOnOffState) - ACRE's own
 *                 signal model decides who is heard;
 *   GVAR(current) the net of the radio in hand;
 *   GVAR(slots)   net -> radio id (the first radio on it).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_acre_fnc_voiceView
 *
 * Public: No
 */

if (isNull player || {isNil "acre_api_fnc_getCurrentRadioList"}) exitWith {};

private _inHand = [] call acre_api_fnc_getCurrentRadio;
private _nets = [];
private _rows = [];
private _slots = createHashMap;
private _current = "";

{
    private _radioId = _x;
    ([_radioId] call FUNC(radioNet)) params ["_net", "_kind"];
    if (_net isEqualTo "") then {continue};
    if (_radioId isEqualTo _inHand) then {_current = _net};
    if (_net in _slots) then {continue};
    _slots set [_net, _radioId];
    private _spatial = [_radioId] call acre_api_fnc_getRadioSpatial;
    private _at = ACRE_SPATIAL findIf {(_x select 0) isEqualTo _spatial};
    private _volume = [_radioId] call acre_api_fnc_getRadioVolume;
    _nets pushBack [_net, _net, _kind, NO_CHANNEL];
    _rows pushBack [
        _net, _net, _kind, false,
        _volume isEqualTo VOLUME_MUTED,
        [EAR_BOTH, (ACRE_SPATIAL select _at) select 1] select (_at >= 0),
        ([_radioId] call acre_api_fnc_getRadioOnOffState) isEqualTo true
    ];
} forEach ([] call acre_api_fnc_getCurrentRadioList);

{
    _x set [3, (_x select 0) isEqualTo _current];
} forEach _rows;

GVAR(nets) = _nets;
GVAR(rows) = _rows;
GVAR(current) = _current;
GVAR(slots) = _slots;
