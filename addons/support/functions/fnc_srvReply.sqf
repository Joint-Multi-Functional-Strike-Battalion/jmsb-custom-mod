#include "script_component.hpp"
/*
 * Author: YonV
 * Server: files one reply in the asset's open support thread - or the thread
 * the provider named, one filed to this asset (2026-11-01) - as the asset:
 * the queued half of FUNC(state), run the frame after it.
 *
 * THE CARD IS PICKED BY ITS STATE, NEVER BY ITS ID (user, 2026-11-01). The
 * deck is mission / PAC data the mod does not own, and what it calls its
 * ROGER or its WILCO cannot be known from here. The card is the first
 * registered template, in EFUNC(messaging,templateIds) order, that answers in
 * a thread (kind "reply" or "both"), transitions to the state, is allowed
 * from where the thread is now and whose sender rule the issuer meets - the
 * same rules EFUNC(messaging,srvThreadFor) applies, checked first because a
 * refusal there would land on the issuer's screen as his own (cltReject). A
 * deck with no card for a state says so once in the RPT and is skipped.
 * Since 2026-11-01: never one of the issuer's own cards (FFE also moves a
 * thread to IN_PROGRESS), and when the asset has something to say, the first
 * card that can carry it - the mod's built-in WILCO and ON TASK carry a
 * DETAIL line (EFUNC(messaging,builtinCards)).
 *
 * ROGER, WILCO AS ONE (user, 2026-11-01): an ACCEPTED or DECLINED inside the
 * receipt's hold (FUNC(srvFiled), RECEIPT_HOLD) is the only answer - the
 * WILCO reads "ROGER, WILCO - <what it said>", the CANTCO its reason.
 *
 * FILED AS THE ISSUER, UNDER THE ASSET'S CALL SIGN. EFUNC(messaging,srvSubmit)
 * files for a player, so the unit is the thread's issuer; the call sign
 * override is honoured for the server, and a message filed under another call
 * sign is not pre-read by its sender - so the asset's answer arrives unread,
 * with a notification, which is what a reply from an asset is. The call sign
 * is the one passed with this state, else the last one a provider passed
 * (FUNC(state)), else the one the requesting client sent (FUNC(srvCallsign)),
 * else the asset id upper-cased - FUNC(srvFileAs) files it.
 *
 * Quiet where nothing is wrong: no thread for the asset, a state the thread
 * is already at or past. Said in the RPT (INFO) where a reply was due and
 * could not be filed: the issuer gone, no card, the card refused.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: State <STRING>
 * 2: What the asset says, "" for nothing <STRING>
 * 3: The call sign to file under, "" for the one the server knows <STRING>
 * 4: Only while nobody has accepted the order yet <BOOL>
 * 5: Only in a thread this player (Steam id) issued, "" for any <STRING>
 * 6: The thread, "" for the asset's open thread <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [{_this call jmfsb_support_fnc_srvReply}, ["fires:1", "CLOSED", "rounds complete", "", false, "", ""]] call CBA_fnc_execNextFrame
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_state", "", [""]],
    ["_said", "", [""]],
    ["_callsign", "", [""]],
    ["_unaccepted", false, [false]],
    ["_onlyFor", "", [""]],
    ["_named", "", [""]]
];

if (!isServer) exitWith {};
// Only ever queued by FUNC(state) on the server; a client's remote call is
// not a provider.
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("srvReply: refused - remote call from machine %1",remoteExecutedOwner);
};

private _open = localNamespace getVariable [QGVAR(threads), createHashMap];
private _assets = localNamespace getVariable [QGVAR(threadAssets), createHashMap];
private _threadId = [_named, _open getOrDefault [_assetId, ""]] select (_named isEqualTo "");
if (_threadId isEqualTo "") exitWith {};

// THE THREAD IS NO LONGER THE ASSET'S - swept, cleared (msg.clear) or over.
// Its links are dropped; the asset's open thread only when it is this one.
private _fnc_drop = {
    _assets deleteAt _threadId;
    if ((_open getOrDefault [_assetId, ""]) isEqualTo _threadId) then {
        _open deleteAt _assetId;
    };
    // Its LZs and DZs go with it, bar a stick's still in the air (FUNC(zones)).
    [_threadId, [], sideUnknown, true] call FUNC(zones);
};
private _thread = (missionNamespace getVariable [QEGVAR(messaging,threads), createHashMap]) getOrDefault [_threadId, createHashMap];
if (_thread isEqualTo createHashMap) exitWith {call _fnc_drop};
private _status = _thread getOrDefault ["status", ""];
if (_thread getOrDefault ["closed", false]) exitWith {call _fnc_drop};
if (_status in STATES_OVER) exitWith {call _fnc_drop};

// A thread named by a provider must be one this asset was given.
if ((_assets getOrDefault [_threadId, ""]) isNotEqualTo _assetId) exitWith {
    WARNING_3("srvReply: %1 %2 refused - thread %3 was not filed to that asset",_assetId,_state,_threadId);
};

private _issuerUid = [_thread] call FUNC(threadIssuer);
if (_onlyFor isNotEqualTo "" && _issuerUid isNotEqualTo _onlyFor) exitWith {
    WARNING_3("srvReply: %1 %2 refused - %3 did not issue that thread",_assetId,_state,_onlyFor);
};
// An end the issuer is not here to read still ends the thread's LZs and DZs.
if (_state in STATES_OVER) then {
    [_threadId, [], sideUnknown, true] call FUNC(zones);
};

// ROGER, WILCO IS ONE MESSAGE (user, 2026-11-01). The receipt FUNC(srvFiled)
// holds for RECEIPT_HOLD s: an ACCEPTED inside it carries the ROGER in its
// text, a DECLINED goes without it - and the thread is put at RECEIPT first,
// silently, so a deck whose WILCO or CANTCO is allowed only from RECEIPT still
// takes it (the forward-only rule is kept: ISSUED, RECEIPT, ACCEPTED). Any
// other state inside the hold: the ROGER is said on its own first.
private _due = localNamespace getVariable [QGVAR(receiptsDue), createHashMap];
private _dueKey = [_threadId, _assetId];
private _merged = false;
if (_dueKey in _due) then {
    _due deleteAt _dueKey;
    switch (true) do {
        case (_state isEqualTo STATE_RECEIPT): {};
        case (_state in RECEIPT_FOLDS): {
            if (_status isEqualTo STATE_ISSUED) then {
                _thread set ["status", STATE_RECEIPT];
                _status = STATE_RECEIPT;
            };
            _merged = true;
        };
        default {
            [_assetId, STATE_RECEIPT, "", _callsign, false, _onlyFor, _threadId] call FUNC(srvReply);
            _status = _thread getOrDefault ["status", ""];
        };
    };
};
if (_merged && _state isEqualTo STATE_ACCEPTED) then {
    _said = [RECEIPT_WILCO, format [RECEIPT_WILCO_WITH, _said]] select (_said isNotEqualTo "");
};

// A refusing ack after the order was taken is about something else (a recall
// that could not be flown, a held strike) - not a CANTCO for the task.
if (_unaccepted && !(_status in STATES_UNACCEPTED)) exitWith {};

// Forward only. CLOSED and DECLINED end the thread from wherever it is.
private _forward = true;
if !(_state in STATES_OVER) then {
    _forward = (STATE_ORDER find _state) > (STATE_ORDER find _status);
};
if (!_forward) exitWith {};

private _at = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
if (_at < 0) exitWith {
    INFO_3("thread %1: %2 %3 not filed - the issuer is not on the server",_threadId,_assetId,_state);
};
private _issuer = allPlayers select _at;
if (!alive _issuer) exitWith {
    INFO_3("thread %1: %2 %3 not filed - the issuer is dead",_threadId,_assetId,_state);
};

// --- the card -----------------------------------------------------------------
private _fnc_card = {
    params ["_id"];
    [_id] call EFUNC(messaging,template)
};
// The key of the card's first text field, "" when it has none.
private _fnc_textKey = {
    params ["_card"];
    private _fields = _card getOrDefault ["fields", createHashMap];
    private _order = _card getOrDefault ["order", []];
    private _at = _order findIf {((_fields getOrDefault [_x, createHashMap]) getOrDefault ["type", ""]) in TEXT_TYPES};
    if (_at < 0) exitWith {""};
    _order select _at
};
// THE ISSUER'S CARDS ARE NEVER THE ASSET'S ANSWER (2026-11-01): FIRE FOR
// EFFECT also moves a thread to IN_PROGRESS, and a deck that lists it before
// ON TASK would have the battery say FFE for its ON TASK.
private _issuerCards = [CARD_CLEARED_HOT] + CARDS_STOP + (FOLLOW_UP_WORDS apply {_x select 0});
private _fits = [];
{
    if (_x in _issuerCards) then {continue};
    private _card = [_x] call _fnc_card;
    if ((_card getOrDefault ["transitionsTo", ""]) isNotEqualTo _state) then {continue};

    // EFUNC(messaging,srvThreadFor)'s sender rules, for the issuer.
    private _may = switch (_card getOrDefault ["senderMustBe", "any"]) do {
        case "assignee": {(_thread getOrDefault ["claimedBy", ""]) in ["", _issuerUid]};
        case "boxMember": {
            private _visible = [_issuer] call EFUNC(messaging,srvBoxesFor);
            ((_thread getOrDefault ["boxes", []]) findIf {_x in _visible}) >= 0
        };
        case "leader": {(_issuer getVariable ["isLeader", false]) isEqualTo true};
        default {true};
    };
    if (_may) then {_fits pushBack _x};
} forEach ([CARD_KIND_REPLY, _status] call EFUNC(messaging,templateIds));

// The first that fits - or, when the asset has something to say, the first
// that can carry it (user, 2026-11-01: the deck's WILCO has no text line, so
// the ETA was never shown; the built-in `accepted` card has one).
private _cardId = _fits param [0, ""];
if (_said isNotEqualTo "") then {
    private _carries = _fits findIf {([[_x] call _fnc_card] call _fnc_textKey) isNotEqualTo ""};
    if (_carries >= 0) then {_cardId = _fits select _carries};
};

if (_cardId isEqualTo "") exitWith {
    private _any = ([CARD_KIND_REPLY] call EFUNC(messaging,templateIds)) findIf {
        (([_x] call _fnc_card) getOrDefault ["transitionsTo", ""]) isEqualTo _state
    };
    if (_any >= 0) exitWith {
        INFO_4("thread %1: %2 %3 not filed - no %3 card may be sent while the thread is %4",_threadId,_assetId,_state,_status);
    };
    // Once per state: a deck without the card stays without it all mission.
    private _told = localNamespace getVariable [QGVAR(noCardSaid), []];
    if (_state in _told) exitWith {};
    _told pushBack _state;
    localNamespace setVariable [QGVAR(noCardSaid), _told];
    INFO_1("threads: the deck has no reply card that moves a thread to %1 - that state is not said",_state);
};

// --- what it says ---------------------------------------------------------------
private _card = [_cardId] call _fnc_card;
private _payload = [];
private _textKey = [_card] call _fnc_textKey;
if (_said isNotEqualTo "" && _textKey isNotEqualTo "") then {
    _payload pushBack [_textKey, _said];
};
([_cardId, _payload] call EFUNC(messaging,validate)) params ["_ok", "_why"];
if (!_ok) exitWith {
    INFO_4("thread %1: %2 %3 not filed - card '%4' would be refused",_threadId,_assetId,_state,_cardId);
    INFO_1("threads: %1",_why);
};

[_assetId, _thread, _cardId, _payload, _callsign, _issuer] call FUNC(srvFileAs);

if (_state in STATES_OVER) then {
    call _fnc_drop;
};
