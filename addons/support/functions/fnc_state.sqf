#include "script_component.hpp"
/*
 * Author: YonV
 * Server: moves the asset's open support thread to a state - the asset
 * answers in it, as itself, with the deck's reply card for that state
 * (FUNC(srvReply)). Providers call it at their natural points (a fire mission
 * starts, a sortie is over, an aircraft is lost); the core calls it for the
 * receipt (FUNC(srvFiled)) and for a provider's ack (FUNC(ack)). An asset
 * nobody filed a thread to is the usual case and nothing is said.
 *
 * QUEUED, NEVER FILED HERE. The reply is filed in the next frame
 * (CBA_fnc_execNextFrame): a provider's server code is often running inside
 * a client's remoteExecCall (FUNC(request) of support_fires, cas), and
 * messaging reads the call now running to decide who filed what - a reply
 * filed from there would be judged as that client's and its call sign
 * override dropped. Queued, the replies keep their order.
 *
 * WHO MAY MOVE A THREAD (review S6/S7). This is not for clients, but a
 * provider's call nested in a client's remoteExecCall looks exactly like a
 * client calling this by remoteExec. So such a call is held to the thread of
 * the man on that machine: it moves the asset's thread only when he is its
 * issuer - a reply he could have filed himself, bar the call sign - and the
 * call sign it names is used for that reply but not kept.
 *
 * WHICH THREAD (2026-11-01). The asset's open thread - the last one filed to
 * it - unless one is named: a provider that acts on more than one thread at a
 * time (a fixed-wing on station is answering its REQUEST ON STATION and a
 * strike) names the one it means. A named thread must be one filed to this
 * asset (FUNC(srvFiled)); the reply is not filed otherwise.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: State - "RECEIPT", "ACCEPTED", "IN_PROGRESS", "CLOSED" or "DECLINED" <STRING>
 * 2: What the asset says, "" for nothing - goes in the card's first text field (a CANTCO's reason) <STRING> (optional, default "")
 * 3: The asset's call sign, "" for the one the server knows <STRING> (optional, default "")
 * 4: Only while nobody has accepted the order yet - FUNC(ack)'s refusal <BOOL> (optional, default false)
 * 5: The thread, "" for the asset's open thread <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["fires:1", "IN_PROGRESS", "", "HAMMER"] call jmfsb_support_fnc_state
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_state", "", [""]],
    ["_said", "", [""]],
    ["_callsign", "", [""]],
    ["_unaccepted", false, [false]],
    ["_threadId", "", [""]]
];

if (!isServer || _assetId isEqualTo "") exitWith {};
if !(_state in STATES) exitWith {
    WARNING_2("state: '%1' for %2 is not a thread state",_state,_assetId);
};

private _onlyFor = "";
private _trusted = [] call EFUNC(common,fromServer);
if (!_trusted) then {
    _onlyFor = ([] call EFUNC(common,sender)) param [2, ""];
};
if (!_trusted && _onlyFor isEqualTo "") exitWith {
    WARNING_2("state: refused - machine %1 has no player (%2)",remoteExecutedOwner,_assetId);
};

_callsign = (trim _callsign) select [0, CALLSIGN_MAX];
if (_trusted && _callsign isNotEqualTo "") then {
    private _names = localNamespace getVariable [QGVAR(callsigns), createHashMap];
    _names set [_assetId, _callsign];
    localNamespace setVariable [QGVAR(callsigns), _names];
};

[{_this call FUNC(srvReply)}, [_assetId, _state, _said, _callsign, _unaccepted, _onlyFor, _threadId]] call CBA_fnc_execNextFrame;
