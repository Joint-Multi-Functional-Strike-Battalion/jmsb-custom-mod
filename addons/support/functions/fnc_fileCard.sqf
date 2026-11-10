#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a provider files a card of its own in a thread filed to its asset,
 * as the asset - the fixed-wing's check-in when it reaches its hold
 * (DESIGN_SUPPORT_MESSAGING 1.1, user 2026-11-01). The state replies go
 * through FUNC(state); this is for a card that is not a state.
 *
 * THE CALL SIGN IS THE ASSET'S (the old doc's T8): a card whose own call sign
 * line is the sender's (`checkin` Line 1, autoFill ownCallsign) is filled by
 * the provider - the server has no "own call sign" to fill it from.
 *
 * QUEUED, like FUNC(state): filed the next frame by FUNC(srvFileCard),
 * outside any client's remoteExecCall, in order with the state replies. A
 * call that is not the server's own is refused: this names the card and its
 * whole text.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Thread id, one filed to this asset <STRING>
 * 2: Card id <STRING>
 * 3: Payload, [fieldKey, value] pairs <ARRAY>
 * 4: The asset's call sign, "" for the one the server knows <STRING> (optional, default "")
 * 5: Priority, "" for the card's own - "high" files it FLASH (2026-11-01, a
 *    CAS prompt that waits to release or says BINGO) <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:0", "T0042", "checkin", [["Line1.A", "HOG"]], "HOG"] call jmfsb_support_fnc_fileCard
 *
 * Public: Yes
 */

params [
    ["_assetId", "", [""]],
    ["_threadId", "", [""]],
    ["_cardId", "", [""]],
    ["_payload", [], [[]]],
    ["_callsign", "", [""]],
    ["_priority", "", [""]]
];

if (!isServer || _assetId isEqualTo "" || _threadId isEqualTo "") exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_2("fileCard: refused - remote call from machine %1 (%2)",remoteExecutedOwner,_cardId);
};

[{_this call FUNC(srvFileCard)}, [_assetId, _threadId, _cardId, _payload, (trim _callsign) select [0, CALLSIGN_MAX], _priority]] call CBA_fnc_execNextFrame;
