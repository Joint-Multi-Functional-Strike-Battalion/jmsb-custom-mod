#include "script_component.hpp"
/*
 * Author: YonV
 * A provider's delivery receipt: the asset took the order, or has not taken it
 * yet. Delivered as [assetId, ok, said] to the hooks registered with
 * FUNC(onAck) - jmfsb_tacpad_apps puts it on the notify rail.
 *
 * Local by default, because today's providers watch for the receipt on the
 * client that sent the order. A provider whose work runs on the server passes
 * the requester and the receipt goes to his machine by remoteExec
 * (FUNC(ackLocal), which takes it only from the server).
 *
 * Review R1: it was the jmfsb_support_ack CBA event, so any client could put
 * a fake receipt on every support board. A remote-executed call is dropped
 * unless the receipt goes back to the sending machine's own unit.
 *
 * NESTED CALLS ARE REMOTE EXECUTED TOO (2026-11-01): a provider's server
 * function reached by a client's remoteExecCall (support_fires fireMission,
 * support_air order) calls this inside that call, and isRemoteExecuted holds
 * for the whole of it - the same rule jmfsb_common_fnc_sender relies on. So
 * every such receipt was dropped. Those calls name the requester, the sender
 * himself; a receipt to anyone else is still refused, so nobody can put one
 * on another man's board.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Acknowledged <BOOL>
 * 2: What to tell the requester <STRING>
 * 3: Requester <OBJECT> (optional, default objNull - deliver it here)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", true, "REAPER 1 acknowledged - wilco"] call jmfsb_support_fnc_ack
 *
 * Public: Yes
 */

params [["_assetId", "", [""]], ["_ok", true, [true]], ["_said", "", [""]], ["_to", objNull, [objNull]]];

if (isRemoteExecuted && {!isServer || {!([_to] call EFUNC(common,senderIs))}}) exitWith {
    WARNING_1("ack: refused - remote call from machine %1",remoteExecutedOwner);
};

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _word = ["not acknowledged", "acknowledged"] select _ok;
INFO_3("ack: %1 %2 - %3",_assetId,_word,_said);

// THE ASSET'S THREAD (2026-11-01): a receipt is a WILCO, a refusal a CANTCO
// with its reason. Only the server files (FUNC(state)); an ack raised on a
// client moves no thread. A refusal counts only while nobody has accepted
// the order yet - after that it is about a recall or a held strike, not
// the task.
if (isServer) then {
    if (_ok) then {
        [_assetId, STATE_ACCEPTED, _said] call FUNC(state);
    } else {
        [_assetId, STATE_DECLINED, _said, "", true] call FUNC(state);
    };
};

if (isNull _to || {local _to}) exitWith {
    [_assetId, _ok, _said] call FUNC(ackLocal);
};
// Only the server forwards to another machine; that machine takes it only
// from the server.
if (!isServer) exitWith {
    WARNING_1("ack: %1 - a client cannot send a receipt to another machine",_assetId);
};
[_assetId, _ok, _said] remoteExecCall [QFUNC(ackLocal), _to];
