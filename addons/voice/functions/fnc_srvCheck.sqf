#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: ends a call that has run out of people - fewer than two members
 * and ringing together, or a live call down to one member.
 *
 * Arguments:
 * 0: Call id <STRING>
 *
 * Return Value:
 * Ended <BOOL>
 *
 * Example:
 * ["123_1"] call jmfsb_voice_fnc_srvCheck
 *
 * Public: No
 */

params [["_callId", "", [""]]];

private _call = GVAR(calls) getOrDefault [_callId, createHashMap];
if (count _call == 0) exitWith {false};

private _members = count (_call get "members");
private _ringing = count (_call get "ringing");
if ((_members + _ringing) >= CALL_MIN_MEMBERS && !((_call get "live") && _members < CALL_MIN_MEMBERS)) exitWith {false};

[_callId, STATE_ENDED] call FUNC(srvEnd);
true
