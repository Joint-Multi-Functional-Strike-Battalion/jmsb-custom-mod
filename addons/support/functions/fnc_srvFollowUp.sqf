#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a reply filed in a thread an asset was given (FUNC(srvFiled)) -
 * passed to the provider's "reply" hook when it is from someone the asset
 * takes follow-ups from (2026-11-01, DESIGN_SUPPORT_MESSAGING step 3: "the
 * aircraft releases only after the issuer's clearedhot reply in the thread").
 *
 * WHO IS LISTENED TO (doc 5.5, D6 decided - user, 2026-11-01: follow-ups are
 * accepted from the issuer, the callforfire Observer, and anyone on the FIRES
 * net):
 *
 *   the issuer       the thread's own
 *   the observer     a man the root card's Observer line names (FUNC(observer):
 *                    his group id or his name, as the card carries it)
 *   the FIRES net    a man who can read the FIRES box or one of its sub-nets
 *                    (FIRES.arty ...) - messaging's own read rule
 *                    (EFUNC(messaging,srvBoxesFor)): his role's nets where the
 *                    mission gates them, everyone where it does not
 *
 * Anyone but the issuer must also be of the asset's side - its provider's
 * "side" hook, else the issuer's (a shared box is readable by every side).
 * Whoever it is, he is asked the tasking gate again (review S6). Never the
 * asset's own answers (FUNC(srvFileAs) keeps their message ids - they are
 * filed as the issuer, under the asset's call sign).
 *
 * The hook is handed the man who sent it and one word for what was said, so
 * no provider has to know the deck's ids:
 *
 *   "cleared"    CLEARED HOT (the `clearedhot` card)
 *   "stop"       anything that ends it - a reply moving the thread to CLOSED
 *                or ABORTED (CLOSE = EOM, ABORT), or the `rtb` / `abort`
 *                cards by id
 *   "adjust", "ffe", "repeat", "checkfire", "confirm", "bda"
 *                the observer's calls and answers (step 6), by their cards
 *                (FOLLOW_UP_WORDS)
 *   "cold", "hot", "paxoff", "hold", "received", "notfound", "no",
 *   "destination"
 *                the answers to the transport, casevac, airdrop and QRF
 *                prompts (step 7, 2026-11-01), by their cards
 *   "correct", "wrong", "nosmoke", "clearedland"
 *                the answers to a landing's prompts (user, 2026-11-02) - taken
 *                by the core's landing wait (FUNC(lzClearReply)), with a HOLD
 *                to READY TO LAND - CLEARED?; the provider is not told
 *   "task"       a task card filed in the thread (a root that moves a thread
 *                into a state - a NEXT LIFT `hlz`, step 7)
 *   2026-11-09 (docs/DESIGN_MESSAGE_TEMPLATES.md): "abort" (ABORT is no
 *                longer a stop - the asset breaks off and asks for
 *                intentions, FUNC(askIntentions)), "move" (MOVE, which
 *                replaced DESTINATION), "confirm" is EXECUTE's (CONFIRM
 *                retired), "nodrop", "clearedengage", "continue", "escort",
 *                "frago" (the message handed over is the current order with
 *                the FRAGO laid over it, the FRAGO itself under "frago");
 *                "continueapproach" and "goaround" are the landing's
 *                (FUNC(lzClearReply)); "status" is answered here
 *                (FUNC(statusReply)) and not passed on
 *   ""           anything else (a free-text message)
 *
 * A follow-up passed on also ends the D9 wait of the asset's open prompt in
 * that thread (FUNC(prompt), step 7).
 *
 * THE BDA IS KEPT ON THE THREAD (doc 5.4, step 5, 2026-11-01): a `bda` card
 * passed on is read (FUNC(readOrder), kind "bda", with "from" and "at") and
 * kept on the thread record (THREAD_BDA, the last one) before the hook hears
 * it - FUNC(threadBda) reads it back. The CAS providers re-attack its target.
 *
 * A thread that was closed is no longer the asset's: its links are dropped
 * after the hook has run.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: Message <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_thread, _message] call jmfsb_support_fnc_srvFollowUp
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]], ["_message", createHashMap, [createHashMap]]];

if (!isServer) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("srvFollowUp: refused - remote call from machine %1",remoteExecutedOwner);
};

// The asset's own answer, filed as the issuer: not his.
private _own = localNamespace getVariable [QGVAR(ownMessages), createHashMap];
private _messageId = _message getOrDefault ["id", ""];
if (_messageId in _own) exitWith {
    _own deleteAt _messageId;
};

private _threadId = _thread getOrDefault ["id", ""];
private _assets = localNamespace getVariable [QGVAR(threadAssets), createHashMap];
private _assetId = _assets getOrDefault [_threadId, ""];
if (_assetId isEqualTo "") exitWith {};

// The issuer closed it (or anyone it reached did): no longer the asset's -
// after the hook has heard it, when it may.
private _fnc_drop = {
    if !(_thread getOrDefault ["closed", false]) exitWith {};
    _assets deleteAt _threadId;
    private _open = localNamespace getVariable [QGVAR(threads), createHashMap];
    if ((_open getOrDefault [_assetId, ""]) isEqualTo _threadId) then {
        _open deleteAt _assetId;
    };
};

private _cardId = _message getOrDefault ["templateId", ""];
private _fromUid = _message getOrDefault ["fromUid", ""];
private _at = allPlayers findIf {(getPlayerUID _x) isEqualTo _fromUid};
if (_at < 0) exitWith {call _fnc_drop};
private _who = allPlayers select _at;

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];

// --- WHO IT IS (D6) -----------------------------------------------------------
// The man the asset takes orders from: the thread's issuer, or the sender of
// the request that pulled it into a report (FUNC(srvFiled), 2026-11-09).
private _issuerUid = (localNamespace getVariable [QGVAR(threadIssuers), createHashMap]) getOrDefault [_threadId, _thread getOrDefault ["issuerUid", ""]];
private _as = "";
if (_fromUid isEqualTo _issuerUid) then {
    _as = "issuer";
} else {
    // Of the asset's side: its provider says, else the issuer's own.
    private _sideCode = _decl getOrDefault ["side", {}];
    private _assetSide = sideUnknown;
    if (_sideCode isNotEqualTo {}) then {
        _assetSide = [_assetId] call _sideCode;
        if (isNil "_assetSide") then {_assetSide = sideUnknown};
    } else {
        private _issuerAt = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
        if (_issuerAt >= 0) then {_assetSide = side group (allPlayers select _issuerAt)};
    };
    if (_assetSide isNotEqualTo (side group _who)) exitWith {};

    private _root = [_thread] call FUNC(threadOrder);
    if (_who in (([_thread, _root] call FUNC(observer)) select 1)) exitWith {_as = "observer"};

    private _fires = ([_who] call EFUNC(messaging,srvBoxesFor)) findIf {
        private _box = toUpper _x;
        _box isEqualTo FIRES_BOX || (_box select [0, count FIRES_BOX_SUB]) isEqualTo FIRES_BOX_SUB
    };
    if (_fires >= 0) then {_as = "FIRES net"};
};
if (_as isEqualTo "") exitWith {
    INFO_3("thread %1: %2's follow-up '%3' not passed on - not the issuer, the observer or on the FIRES net",_threadId,_assetId,_cardId);
    call _fnc_drop;
};

([_who] call FUNC(canTask)) params ["_may", "_gateWhy"];
if (!_may) exitWith {
    WARNING_3("thread %1: %2's follow-up '%3' not passed on - the sender may not task",_threadId,_assetId,_cardId);
    call _fnc_drop;
};

private _word = switch (true) do {
    case (_cardId isEqualTo CARD_CLEARED_HOT): {WORD_CLEARED};
    case (_cardId in CARDS_STOP): {WORD_STOP};
    case ((_message getOrDefault ["transition", ""]) in TRANSITIONS_STOP): {WORD_STOP};
    default {
        private _pair = FOLLOW_UP_WORDS select {(_x select 0) isEqualTo _cardId};
        private _said = (_pair param [0, ["", ""]]) select 1;
        // A TASK CARD in the thread (step 7): a root card, not a reply, that
        // moves a thread into a state - a NEXT LIFT.
        private _card = [_cardId] call EFUNC(messaging,template);
        if (_said isEqualTo "" && (_card getOrDefault ["kind", CARD_KIND_REPLY]) isNotEqualTo CARD_KIND_REPLY && (_card getOrDefault ["transitionsTo", ""]) isNotEqualTo "") then {
            _said = WORD_TASK;
        };
        _said
    };
};

// THE BDA, KEPT ON THE THREAD (step 5): the newest one.
if ((BDA_CARDS findIf {(_x select 0) isEqualTo _cardId}) >= 0) then {
    private _bda = [_thread, _message] call FUNC(readOrder);
    _bda set ["from", name _who];
    _bda set ["at", CBA_missionTime];
    _thread set [THREAD_BDA, _bda];
};

// THE ASSET'S PROMPT IS ANSWERED (D9, step 7): its waits end.
private _seqs = localNamespace getVariable [QGVAR(promptSeqs), createHashMap];
_seqs set [_threadId, (_seqs getOrDefault [_threadId, 0]) + 1];
localNamespace setVariable [QGVAR(promptSeqs), _seqs];
// And off the observers' phones (2026-11-06): they are not sent the answer.
[_threadId] call FUNC(askObservers);

// STATUS IS THE CORE'S (2026-11-09): the asset's STATUS REPLY - position,
// task, time left on station, fuel, ammo, pax (FUNC(statusReply)). The
// provider is not told.
if (_word isEqualTo WORD_STATUS) exitWith {
    INFO_3("thread %1: %2 asked its status by the %3",_threadId,_assetId,_as);
    [_assetId, _threadId] call FUNC(statusReply);
    call _fnc_drop;
};

// A FRAGO (2026-11-09) is handed over as the order it changes, re-filed with
// the changes laid over it (FUNC(threadOrder) - messaging stored the FRAGO
// already, so the merge includes it): the provider re-plans from that, word
// WORD_FRAGO, and keeps the FRAGO's own message for what changed.
if (_word isEqualTo WORD_FRAGO) then {
    private _merged = [_thread] call FUNC(threadOrder);
    if (count _merged isEqualTo 0) exitWith {};
    _merged set ["frago", _message];
    _merged set ["id", _messageId];
    _merged set ["fromUid", _fromUid];
    _message = _merged;
};

// THE LANDING'S ANSWERS ARE THE CORE'S (user, 2026-11-02, FUNC(lzClear)):
// CORRECT, WRONG, NO SMOKE, CLEARED TO LAND, and a HOLD to READY TO LAND -
// CLEARED?. A stop ends the wait and goes on to the provider.
if ([_threadId, _word] call FUNC(lzClearReply)) exitWith {
    INFO_4("thread %1: %2's landing told '%3' by the %4",_threadId,_assetId,_word,_as);
    call _fnc_drop;
};

private _hook = _decl getOrDefault ["reply", {}];
if (_kind isNotEqualTo "" && _hook isNotEqualTo {}) then {
    INFO_5("thread %1: %2 told '%3' (%4) by the %5",_threadId,_assetId,_cardId,_word,_as);
    [_assetId, _thread, _message, _who, _word] call _hook;
};

call _fnc_drop;
