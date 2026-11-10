#include "script_component.hpp"
/*
 * Author: YonV
 * Server: keeps the call sign an asset answers its thread under (FUNC(srvReply))
 * - reached by remoteExec from FUNC(request) on the client that got an
 * accepted order, with the call sign from the provider's row, and from
 * FUNC(mailboxFiled) on a client filing a message to the asset's mailbox from
 * TAC//MSG (2026-11-01), with the same row's name.
 *
 * WHY THE CLIENT SAYS IT (2026-11-01). A provider's `assets` answers for the
 * viewer (`player`), which is null on a dedicated server, so the server
 * cannot ask for the row itself. A provider that knows the call sign server
 * side passes it to FUNC(state), and that one wins over this.
 *
 * THE SERVER TRUSTS ONLY WHAT IT CAN CHECK, as FUNC(bookCooldown) (review
 * S6): the sender is the sending machine's own player and must pass the
 * tasking tag gate (FUNC(canTask)); the id must name a registered provider;
 * the call sign is trimmed and capped at CALLSIGN_MAX. It is a name on a
 * reply and nothing else - it routes nothing and grants nothing.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: The asset's call sign, the row's field 2 <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", "REAPER 1"] remoteExecCall ["jmfsb_support_fnc_srvCallsign", 2]
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_callsign", "", [""]]];

if (!isServer || _assetId isEqualTo "") exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull _unit) exitWith {
    WARNING_2("srvCallsign: refused - machine %1 has no player (%2)",_owner,_assetId);
};
if !(([_unit] call FUNC(canTask)) select 0) exitWith {
    WARNING_2("srvCallsign: refused - %1 may not task (%2)",_unit,_assetId);
};
if ((([_assetId] call FUNC(provider)) select 0) isEqualTo "") exitWith {
    WARNING_2("srvCallsign: refused - no provider answers for '%1' (from %2)",_assetId,_unit);
};

_callsign = (trim _callsign) select [0, CALLSIGN_MAX];
if (_callsign isEqualTo "") exitWith {};

// localNamespace: not networked, so no client can publicVariable over it.
// Its own table, so a client never overwrites what a provider told the
// server (FUNC(state) keeps those in QGVAR(callsigns), read first).
private _names = localNamespace getVariable [QGVAR(clientCallsigns), createHashMap];
_names set [_assetId, _callsign];
localNamespace setVariable [QGVAR(clientCallsigns), _names];
