#include "script_component.hpp"
/*
 * Author: YonV
 * Server: files one card in a support thread AS THE ASSET - the one filing
 * path of the state replies (FUNC(srvReply)) and of the cards a provider
 * files itself (FUNC(srvFileCard): a check-in).
 *
 * FILED AS THE ISSUER, UNDER THE ASSET'S CALL SIGN (EFUNC(messaging,srvSubmit)
 * files for a player; the call sign override is honoured for the server). So
 * the message carries the issuer's uid, and FUNC(srvFollowUp) would take it
 * for his own: its id is kept here, and that hook passes it by.
 *
 * The call sign is the one given, else the last one a provider passed
 * (FUNC(state)), else the one the requesting client sent (FUNC(srvCallsign)),
 * else the asset id upper-cased. The checks - the thread open, the card valid,
 * the issuer here and alive - are the caller's.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread <HASHMAP>
 * 2: Card id <STRING>
 * 3: Payload, [fieldKey, value] pairs <ARRAY>
 * 4: Call sign, "" for the one the server knows <STRING>
 * 5: The thread's issuer <OBJECT>
 * 6: Priority, "" for the card's own - PRIORITY_FLASH for a FLASH prompt (2026-11-01) <STRING> (optional, default "")
 *
 * Return Value:
 * Filed <BOOL>
 *
 * Example:
 * ["cas:0", _thread, "wilco", [], "REAPER 1", _issuer] call jmfsb_support_fnc_srvFileAs
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_cardId", "", [""]],
    ["_payload", [], [[]]],
    ["_callsign", "", [""]],
    ["_issuer", objNull, [objNull]],
    ["_priority", "", [""]]
];

if (!isServer || isNull _issuer) exitWith {false};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("srvFileAs: refused - remote call from machine %1",remoteExecutedOwner);
    false
};

if (_callsign isEqualTo "") then {
    _callsign = (localNamespace getVariable [QGVAR(callsigns), createHashMap]) getOrDefault [_assetId, ""];
};
if (_callsign isEqualTo "") then {
    _callsign = (localNamespace getVariable [QGVAR(clientCallsigns), createHashMap]) getOrDefault [_assetId, ""];
};
if (_callsign isEqualTo "") then {
    _callsign = toUpper _assetId;
};

private _threadId = _thread getOrDefault ["id", ""];
private _messages = _thread getOrDefault ["messages", []];
private _before = count _messages;

private _seq = (localNamespace getVariable [QGVAR(replySeq), 0]) + 1;
localNamespace setVariable [QGVAR(replySeq), _seq];
private _nonce = format ["%1:%2:%3", NONCE_PREFIX, _assetId, _seq];

[_issuer, _nonce, _cardId, _payload, [], _threadId, "", _callsign, [], [], _priority] call EFUNC(messaging,srvSubmit);

// srvSubmit files at once or refuses; what it filed is the thread's newest.
if (count _messages <= _before) exitWith {
    INFO_3("thread %1: %2's '%3' was refused by messaging",_threadId,_assetId,_cardId);
    false
};
private _own = localNamespace getVariable [QGVAR(ownMessages), createHashMap];
_own set [_messages select -1, true];
localNamespace setVariable [QGVAR(ownMessages), _own];

INFO_4("thread %1: %2 answered '%3' as %4",_threadId,_assetId,_cardId,_callsign);
true
