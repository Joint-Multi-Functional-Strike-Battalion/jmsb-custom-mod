#include "script_component.hpp"
/*
 * Author: JMSB
 * Sends a speaker's gain and ear (FUNC(gainOf)) to the extension, when the
 * gain moved by GAIN_EPS or the ear by PAN_EPS since the last sent - the
 * extension mixes him with it until told otherwise, and keeps it while his
 * audio restarts. Receives him or not (the extension's "subscribe") as he
 * could be heard or not (FUNC(canHear)), on a change. Only while the room is
 * live.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * [gain, pan] as sent or as it stands <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_adapter_livekit_fnc_speaker
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || GVAR(state) isNotEqualTo ROOM_LIVE) exitWith {[0, 0]};
private _uid = getPlayerUID _unit;
if (_uid isEqualTo "") exitWith {[0, 0]};

([_unit] call FUNC(gainOf)) params ["_gain", "_pan"];

private _hear = _gain > 0 || {[_unit] call FUNC(canHear)};
if ((GVAR(subs) getOrDefault [_uid, false]) isNotEqualTo _hear) then {
    ["subscribe", [_uid, _hear]] call FUNC(ext);
    GVAR(subs) set [_uid, _hear];
};

(GVAR(sent) getOrDefault [_uid, [-1, 0]]) params ["_wasGain", "_wasPan"];
if (abs (_gain - _wasGain) >= GAIN_EPS || {abs (_pan - _wasPan) >= PAN_EPS}) then {
    ["speaker", [_uid, _gain, _pan]] call FUNC(ext);
    GVAR(sent) set [_uid, [_gain, _pan]];
};
[_gain, _pan]
