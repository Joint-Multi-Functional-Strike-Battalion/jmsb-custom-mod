#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the messaging hook (EFUNC(messaging,onFiled), registered in
 * XEH_postInit) that turns a thread filed to an asset's box into that asset's
 * open thread, answers it RECEIPT at once, and hands a task card to the
 * provider that flies the asset (2026-11-01, DESIGN_SUPPORT_MESSAGING step 3).
 * A reply in such a thread goes to FUNC(srvFollowUp).
 *
 * ONE MAILBOX PER ASSET (design D6, user 2026-11-01): "B:SUPPORT:<assetId>",
 * the id exactly as the provider hands it out ("B:SUPPORT:fires:1"). TAC//MSG
 * or a script files to it like to any shared box - a bare "SUPPORT:fires:1"
 * reaches the same box (EFUNC(messaging,srvBox)). Only the ROOT of a thread
 * does this, and only for an id whose kind a provider registered. A newer
 * thread to the same asset replaces the older as its open thread: the asset
 * answers the last thing it was asked.
 *
 * THE ISSUER IS ASKED AGAIN (review S6), before the thread is the asset's: he
 * must be on the server, pass the tasking gate (FUNC(canTask)) and - where the
 * provider can say whose the asset is (its "side" hook) - be of the asset's
 * side. A thread that fails is not the asset's and is not answered: an enemy
 * filing to a box must not take over the thread its own side is being
 * answered in.
 *
 * THE PROVIDER ACTS ON A TASK CARD (a thread whose root moves it into a state;
 * a plain message is not one) through its "thread" hook, on the server:
 * [assetId, thread, root message, issuer] -> [ok, why]. It finds its asset by
 * id itself and re-runs its own checks - `assets` answers for `player` and
 * cannot run on a dedicated server. A refusal is the CANTCO, filed here with
 * its reason, and the asset's open thread goes back to the one before; an
 * answer shorter than [ok, why] means the card is not the provider's and the
 * thread stays at RECEIPT. Accepted, the provider says WILCO and the rest
 * itself (FUNC(state), naming the thread).
 *
 * The receipt goes through FUNC(state) like every other state, so a deck with
 * no RECEIPT card, or a root whose status no RECEIPT card is allowed from (a
 * plain message is OPEN), is skipped there and said in the RPT. It waits
 * RECEIPT_HOLD s first (user, 2026-11-01): an asset that answers inside that
 * says ROGER, WILCO as one message (FUNC(srvReply)).
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: Message <HASHMAP>
 * 2: Box ids the thread is filed in <ARRAY of STRINGs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{_this call jmfsb_support_fnc_srvFiled}] call jmfsb_messaging_fnc_onFiled
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]], ["_message", createHashMap, [createHashMap]], ["_boxIds", [], [[]]]];

if (!isServer) exitWith {};
// Run by messaging's own queue on the server; a client's remote call is not.
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("srvFiled: refused - remote call from machine %1",remoteExecutedOwner);
};

private _threadId = _thread getOrDefault ["id", ""];
if (_threadId isEqualTo "") exitWith {};

private _prefixLength = count SUPPORT_BOX_PREFIX;
private _linked = localNamespace getVariable [QGVAR(threadAssets), createHashMap];
private _issuerUid = _thread getOrDefault ["issuerUid", ""];

// A REPLY - unless it is a starter that pulls a new asset into the thread
// (docs/DESIGN_MESSAGE_TEMPLATES.md rule 3, decision 4, 2026-11-09): a CAS,
// fires, CASEVAC or QRF request filed in a TIC, SALUTE or MIST thread and
// addressed to an asset that does not answer in it yet (FUNC(srvThreadCard)
// took it). That asset is given the thread here as if it had been opened to
// it, the request is its order, and its sender is the man it takes orders
// from in the thread (THREAD_ISSUERS - the report's sender may be someone
// else). Anything else goes to FUNC(srvFollowUp).
if ((_message getOrDefault ["seq", -1]) isNotEqualTo 0) exitWith {
    private _card = [_message getOrDefault ["templateId", ""]] call EFUNC(messaging,template);
    private _starter = (_card getOrDefault ["kind", ""]) in [CARD_KIND_ROOT, "both"] && {(_card getOrDefault ["transitionsTo", ""]) isNotEqualTo ""};
    private _new = _boxIds select {
        _x isEqualType ""
        && {(toUpper (_x select [0, _prefixLength])) isEqualTo SUPPORT_BOX_PREFIX}
        && {(_linked getOrDefault [_threadId, ""]) isNotEqualTo (_x select [_prefixLength])}
    };
    if (!_starter || {_new isEqualTo []} || {(_linked getOrDefault [_threadId, ""]) isNotEqualTo ""}) exitWith {
        [_thread, _message] call FUNC(srvFollowUp);
    };
    private _sender = _message getOrDefault ["fromUid", ""];
    private _issuers = localNamespace getVariable [QGVAR(threadIssuers), createHashMap];
    _issuers set [_threadId, _sender];
    localNamespace setVariable [QGVAR(threadIssuers), _issuers];
    INFO_3("thread %1: a '%2' pulls %3 into the thread",_threadId,_message getOrDefault [ARR_2("templateId","")],_new joinString ", ");
    [_thread, _message, _new, _sender] call FUNC(srvTake);
};

[_thread, _message, _boxIds, _issuerUid] call FUNC(srvTake);
