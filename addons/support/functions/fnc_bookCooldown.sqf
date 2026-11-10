#include "script_component.hpp"
/*
 * Author: YonV
 * Server: books a provider's cooldown in the core ledger and publishes it -
 * reached by remoteExec from FUNC(request) on the client that got the
 * accepted order. A cooldown has to hold for every player on the side, so
 * the ledger is the server's.
 *
 * THE SERVER TRUSTS ONLY WHAT IT CAN CHECK (review S6). The sender is the
 * sending machine's own player (EFUNC(common,sender)) and must pass the
 * tasking tag gate (FUNC(canTask)); the id must name a registered provider.
 * The clock is the server's: the call carries seconds, capped at
 * COOLDOWN_MAX, and a booking only ever lengthens a running cooldown, so no
 * client can clear one or hold an asset for good.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Seconds the asset is held <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", 300] remoteExecCall ["jmfsb_support_fnc_bookCooldown", 2]
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_seconds", 0, [0]]];

if (!isServer || _assetId isEqualTo "" || _seconds <= 0) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull _unit) exitWith {
    WARNING_2("bookCooldown: refused - machine %1 has no player (%2)",_owner,_assetId);
};
if !(([_unit] call FUNC(canTask)) select 0) exitWith {
    WARNING_2("bookCooldown: refused - %1 may not task (%2)",_unit,_assetId);
};
if ((([_assetId] call FUNC(provider)) select 0) isEqualTo "") exitWith {
    WARNING_2("bookCooldown: refused - no provider answers for '%1' (from %2)",_assetId,_unit);
};

// The server's own ledger lives in localNamespace, which is not networked
// (recommendation R1): any client can publicVariable GVAR(readyAt) over the
// server's copy, so that copy is only ever written from this one.
private _ledger = localNamespace getVariable [QGVAR(ledger), createHashMap];
private _until = CBA_missionTime + (_seconds min COOLDOWN_MAX);
if (_until <= (_ledger getOrDefault [_assetId, 0])) exitWith {};

_ledger set [_assetId, _until];
localNamespace setVariable [QGVAR(ledger), _ledger];
GVAR(readyAt) = +_ledger;
publicVariable QGVAR(readyAt);
INFO_3("cooldown: %1 ready again at %2 (booked by %3)",_assetId,_until,_unit);
