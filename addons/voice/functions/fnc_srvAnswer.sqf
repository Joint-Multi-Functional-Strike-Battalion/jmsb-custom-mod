#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a ringing person accepts or declines. Accepting joins him to the
 * call net (and the whole call, the moment it goes live); declining tells
 * the caller.
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
 * ["123_1", player, true] call jmfsb_voice_fnc_srvAnswer
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_unit", objNull, [objNull]], ["_accept", true, [true]]];

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
        [QGVAR(callFailed), [_callId, REASON_DECLINED, [_unit]], _from] call CBA_fnc_targetEvent;
    };
};

[_callId] call FUNC(srvCheck);
[] call FUNC(srvPublish);
