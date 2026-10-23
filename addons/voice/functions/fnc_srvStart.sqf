#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: opens a call in a free slot. The people in "ringing" ring until
 * they accept or decline; the call goes live (its members join the call
 * net through the adapter) from CALL_MIN_MEMBERS members.
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: From <OBJECT>
 * 2: Members already in <ARRAY of OBJECTs>
 * 3: Ringing <ARRAY of OBJECTs>
 * 4: Priority <STRING>
 * 5: Slot index, 0-based <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["123_1", player, [player], [_unit], "ROUTINE", 0] call jmfsb_voice_fnc_srvStart
 *
 * Public: No
 */

params [
    ["_callId", "", [""]],
    ["_from", objNull, [objNull]],
    ["_members", [], [[]]],
    ["_ringing", [], [[]]],
    ["_priority", PRIO_ROUTINE, [""]],
    ["_slot", 0, [0]]
];

private _now = CBA_missionTime;
GVAR(slots) set [_slot, _callId];
private _call = createHashMapFromArray [
    ["id", _callId],
    ["slot", _slot + 1],
    ["from", _from],
    // THE OWNER INVITES (user, 2026-10-20: "its not the rto inviting folks its
    // the channel owner so who started the call"). Passes on if he leaves.
    ["owner", _from],
    ["members", +_members],
    ["ringing", _ringing apply {[_x, _now]}],
    ["priority", _priority],
    ["startedAt", _now],
    ["live", false],
    ["bumpAt", -1],
    ["bumpFor", []],
    ["lost", createHashMap]
];
GVAR(calls) set [_callId, _call];

if (count _members >= CALL_MIN_MEMBERS) then {
    _call set ["live", true];
    private _net = format [CALL_FORMAT, _slot + 1];
    {
        [_x, _net] call HOOK("join");
    } forEach _members;
};
INFO_3("call %1 in slot %2, %3",_callId,_slot + 1,_priority);
