#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: someone leaves a call (hang-up, dropped, gone). A member leaves
 * the call net; someone ringing just stops ringing. The caller hanging up
 * before anyone answered ends the dial; otherwise the call ends when one
 * person is left.
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", player] call jmfsb_voice_fnc_srvLeave
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_unit", objNull, [objNull]]];

private _call = GVAR(calls) getOrDefault [_callId, createHashMap];
if (count _call == 0) exitWith {};

private _members = _call get "members";
private _i = _members find _unit;
if (_i >= 0) then {
    _members deleteAt _i;
    if ((_call get "live") && !isNull _unit) then {
        [_unit, format [CALL_FORMAT, _call get "slot"]] call HOOK("leave");
    };
    // The owner left a call that goes on: the longest-standing member owns it.
    if (_unit isEqualTo (_call getOrDefault ["owner", objNull]) && {_members isNotEqualTo []}) then {
        _call set ["owner", _members select 0];
    };
} else {
    private _ringing = _call get "ringing";
    private _r = _ringing findIf {(_x select 0) isEqualTo _unit};
    if (_r >= 0) then {_ringing deleteAt _r};
};

if (!(_call get "live") && _unit isEqualTo (_call get "from")) then {
    [_callId, STATE_ENDED] call FUNC(srvEnd);
} else {
    [_callId] call FUNC(srvCheck);
};
[] call FUNC(srvPublish);
