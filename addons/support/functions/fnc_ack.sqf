#include "script_component.hpp"
/*
 * Author: JMSB
 * A provider's delivery receipt: the asset took the order, or has not taken it
 * yet. Delivered as [assetId, ok, said] to the hooks registered with
 * FUNC(onAck) - TAC//SUPPORT puts it in the verdict row and the notify rail.
 *
 * Local by default, because today's providers watch for the receipt on the
 * client that sent the order. A provider whose work runs on the server passes
 * the requester and the receipt goes to his machine by remoteExec
 * (FUNC(ackLocal), which takes it only from the server).
 *
 * Review R1: it was the jmfsb_support_ack CBA event, so any client could put
 * a fake receipt on every support board. A remote-executed call is dropped:
 * providers call this on their own machine.
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

if (isRemoteExecuted) exitWith {
    WARNING_1("ack: refused - remote call from machine %1",remoteExecutedOwner);
};

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _word = ["not acknowledged", "acknowledged"] select _ok;
INFO_3("ack: %1 %2 - %3",_assetId,_word,_said);

if (isNull _to || {local _to}) exitWith {
    [_assetId, _ok, _said] call FUNC(ackLocal);
};
// Only the server forwards to another machine; that machine takes it only
// from the server.
if (!isServer) exitWith {
    WARNING_1("ack: %1 - a client cannot send a receipt to another machine",_assetId);
};
[_assetId, _ok, _said] remoteExecCall [QFUNC(ackLocal), _to];
