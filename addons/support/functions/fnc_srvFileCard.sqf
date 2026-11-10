#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the queued half of FUNC(fileCard) - files a provider's own card in a
 * thread filed to its asset, as the asset (FUNC(srvFileAs)).
 *
 * Quiet where the thread is gone or over; said in the RPT (INFO) where the
 * card could not be filed: not this asset's thread, the issuer gone, the card
 * invalid for the deck.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id <STRING>
 * 2: Card id <STRING>
 * 3: Payload <ARRAY>
 * 4: Call sign, "" for the one the server knows <STRING>
 * 5: Priority, "" for the card's own <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [{_this call jmfsb_support_fnc_srvFileCard}, ["air:0", "T0042", "checkin", [], "HOG"]] call CBA_fnc_execNextFrame
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_cardId", "", [""]],
    ["_payload", [], [[]]],
    ["_callsign", "", [""]],
    ["_priority", "", [""]]
];

if (!isServer) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("srvFileCard: refused - remote call from machine %1",remoteExecutedOwner);
};

if (((localNamespace getVariable [QGVAR(threadAssets), createHashMap]) getOrDefault [_threadId, ""]) isNotEqualTo _assetId) exitWith {
    INFO_3("thread %1: %2's '%3' not filed - not a thread of that asset (or over)",_threadId,_assetId,_cardId);
};

private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {};
if (_thread getOrDefault ["closed", false]) exitWith {};
if ((_thread getOrDefault ["status", ""]) in STATES_OVER) exitWith {};

private _issuerUid = [_thread] call FUNC(threadIssuer);
private _at = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
if (_at < 0) exitWith {
    INFO_3("thread %1: %2's '%3' not filed - the issuer is not on the server",_threadId,_assetId,_cardId);
};
private _issuer = allPlayers select _at;
if (!alive _issuer) exitWith {
    INFO_3("thread %1: %2's '%3' not filed - the issuer is dead",_threadId,_assetId,_cardId);
};

([_cardId, _payload] call EFUNC(messaging,validate)) params ["_ok", "_why"];
if (!_ok) exitWith {
    INFO_4("thread %1: %2's '%3' not filed - %4",_threadId,_assetId,_cardId,_why);
};

[_assetId, _thread, _cardId, _payload, _callsign, _issuer, _priority] call FUNC(srvFileAs);
