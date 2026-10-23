#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: ends a call. Its members leave the call net through the adapter
 * and the slot is freed (VON: the custom channel is emptied, ready for the
 * next call). A bumped call's people are told why.
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Reason <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", "ended"] call jmfsb_voice_fnc_srvEnd
 *
 * Public: No
 */

params [["_callId", "", [""]], ["_reason", STATE_ENDED, [""]]];

private _call = GVAR(calls) getOrDefault [_callId, createHashMap];
if (count _call == 0) exitWith {};

private _net = format [CALL_FORMAT, _call get "slot"];
private _members = _call get "members";
if (_call get "live") then {
    {
        [_x, _net] call HOOK("leave");
    } forEach (_members select {!isNull _x});
};
if (_reason isEqualTo REASON_BUMPED) then {
    {
        [QGVAR(callFailed), [_callId, REASON_BUMPED, []], _x] call CBA_fnc_targetEvent;
    } forEach ((_members + ((_call get "ringing") apply {_x select 0})) select {!isNull _x});
};

GVAR(slots) set [(_call get "slot") - 1, ""];
GVAR(calls) deleteAt _callId;
INFO_2("call %1 ended: %2",_callId,_reason);
