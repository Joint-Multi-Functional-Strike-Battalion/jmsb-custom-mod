#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the messaging hook (EFUNC(messaging,onThreadCard), registered in
 * XEH_postInit) that rules on a card a player files into a thread already
 * open (2026-11-02). Asked inside EFUNC(messaging,srvThreadFor), before its
 * own sender checks, which still run after a card is taken.
 *
 * EACH STARTER IS THE NEXT TASKING (docs/DESIGN_MESSAGE_TEMPLATES.md, threads
 * rules 1 and 4, 2026-11-09: "the rule has to open up"). A ROOT card the
 * thread's asset flies there (FUNC(threadCards), for the thread's CURRENT
 * order - FUNC(threadOrder) - not only its first card) is taken -
 * THREAD_CARD_TAKE - from the man the asset takes orders from in it;
 * FUNC(srvFollowUp) hands it to the provider as WORD_TASK and the asset
 * answers with a fresh WILCO.
 *
 * A REPORT HOSTS THE REQUEST (rule 3, decision 4). A support starter
 * (PIN_CARDS) filed in a TIC, SALUTE or MIST thread (REPORT_HOSTS) is taken
 * from anyone the thread reaches: it pulls the asset it is addressed to into
 * that thread (FUNC(srvFiled)) and stays there. Once an asset answers in it,
 * the asset's own rule above applies.
 *
 * THE ASSET'S WORDS ARE THE ASSET'S. ROGER, WILCO, ON TASK and CANTCO (a card
 * moving the thread to THREAD_ASSET_STATES that is not one of the issuer's
 * calls - FUNC(assetCard)) and every card the asset says (assetOnly: SHOT,
 * WHEELS DOWN, STATUS REPLY ...) are refused from every player in a thread an
 * asset answers (FUNC(srvFiled)) - the asset files them itself, as the
 * issuer under its call sign (FUNC(srvFileAs)), which messaging does not put
 * to this hook. In a support card's thread to a player crew (a P: box) the
 * crew answers them; only the issuer is refused.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: The card's template <HASHMAP>
 * 2: The sender <OBJECT>
 *
 * Return Value:
 * "" no opinion, THREAD_CARD_TAKE, or why it is refused <STRING>
 *
 * Example:
 * [{_this call jmfsb_support_fnc_srvThreadCard}] call jmfsb_messaging_fnc_onThreadCard
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]], ["_template", createHashMap, [createHashMap]], ["_unit", objNull, [objNull]]];

if (!isServer) exitWith {""};

private _threadId = _thread getOrDefault ["id", ""];
private _cardId = _template getOrDefault ["id", ""];
private _short = toUpper (_template getOrDefault ["short", _cardId]);
private _rootId = _thread getOrDefault ["rootTemplateId", ""];
private _assetId = (localNamespace getVariable [QGVAR(threadAssets), createHashMap]) getOrDefault [_threadId, ""];
private _issuerUid = (localNamespace getVariable [QGVAR(threadIssuers), createHashMap]) getOrDefault [_threadId, _thread getOrDefault ["issuerUid", ""]];
private _isIssuer = (getPlayerUID _unit) isEqualTo _issuerUid;

// The asset's states and the asset's calls.
private _supportRoots = flatten (MAILBOX_TYPES apply {_x select 2});
private _state = [_cardId] call FUNC(assetCard);
if (_state && (_assetId isNotEqualTo "" || (_isIssuer && _rootId in _supportRoots))) exitWith {
    INFO_3("thread %1: '%2' from %3 refused - the asset's to send",_threadId,_cardId,name _unit);
    format [THREAD_ASSET_WHY, _short]
};

if ((_template getOrDefault ["kind", ""]) isNotEqualTo CARD_KIND_ROOT) exitWith {""};

// A report hosting a support request.
if (_assetId isEqualTo "") exitWith {
    if (_rootId in REPORT_HOSTS && {_cardId in PIN_CARDS}) exitWith {
        INFO_3("thread %1: a '%2' from %3 taken into the report",_threadId,_cardId,name _unit);
        THREAD_CARD_TAKE
    };
    ""
};

// The asset's next tasking - the cards it flies after its current order.
private _current = ([_thread] call FUNC(threadOrder)) getOrDefault ["templateId", _rootId];
private _flies = ([_assetId, _current] call FUNC(threadCards)) + ([_assetId, _rootId] call FUNC(threadCards));
if !(_cardId in _flies) exitWith {""};
if (!_isIssuer) exitWith {format [THREAD_ISSUER_WHY, _short]};

INFO_3("thread %1: a new '%2' for %3 taken into the thread",_threadId,_cardId,_assetId);
THREAD_CARD_TAKE
