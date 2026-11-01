#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a ringing person accepts or declines. Accepting joins him to the
 * call net (and the whole call, the moment it goes live); declining tells
 * the caller. Reached by remoteExec from FUNC(callAccept) / callDecline: the
 * unit must be the sender (jmfsb_common_fnc_senderIs). The decline goes to
 * the caller by remoteExec (FUNC(callFailed)).
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Unit <OBJECT>
 * 2: Accept <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", player, true] remoteExecCall ["jmfsb_voice_fnc_srvAnswer", 2]
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_unit", objNull, [objNull]], ["_accept", true, [true]]];

if (!isServer || {!([_unit] call EFUNC(common,senderIs))}) exitWith {};
private _call = GVAR(calls) getOrDefault [_callId, createHashMap];
if (count _call == 0 || isNull _unit) exitWith {};
private _ringing = _call get "ringing";
private _i = _ringing findIf {(_x select 0) isEqualTo _unit};
if (_i < 0) exitWith {};
_ringing deleteAt _i;

if (_accept) then {
    private _members = _call get "members";
    _members pushBack _unit;
    private _net = format [CALL_FORMAT, _call get "slot"];
    if (_call get "live") then {
        [_unit, _net] call HOOK("join");
    } else {
        if (count _members >= CALL_MIN_MEMBERS) then {
            _call set ["live", true];
            {
                [_x, _net] call HOOK("join");
            } forEach _members;
        };
    };
} else {
    private _from = _call get "from";
    if (!isNull _from && _from isNotEqualTo _unit) then {
        [_callId, REASON_DECLINED, [_unit]] remoteExecCall [QFUNC(callFailed), _from];
    };
};

[_callId] call FUNC(srvCheck);
[] call FUNC(srvPublish);
