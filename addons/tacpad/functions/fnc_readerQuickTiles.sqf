#include "script_component.hpp"
/*
 * Author: YonV
 * The quick-reply tiles under an opened thread (FUNC(readerQuick)): which
 * replies, with what on each tile, and what a press does.
 *
 * WHAT THE ASSET ASKED, FIRST (docs/DESIGN_SUPPORT_MESSAGING.md 5.4 and 7,
 * user 2026-11-01: "per the doc i want to use the messaging system to call ai
 * support"). While the newest message on the thread is the asset's `prompt`
 * card, its Answers - reply card ids, comma-separated - are the row: ADJUST?
 * offers ADD, DROP, LEFT, RIGHT, FFE and EOM. A prompt whose answers the
 * thread will take none of falls back to the rules below.
 *
 * A NEW TASK IN THE THREAD (2026-11-02): an answer that is a ROOT card the
 * asset takes in its thread (jmfsb_support_fnc_threadCards, offered to the
 * issuer by FUNC(threadLegal)) - CAS on FURTHER TASKING?, LIFT on HOLD, RTB
 * OR NEXT LIFT? - is a QUICK_TASK tile: the composer on that card, in the
 * thread (FUNC(taskInThread)).
 *
 * THEN THE SUPPORT CARD'S OWN ROW, TO ITS SENDER (doc 6.2): a `cas` thread
 * offers CLEARED HOT, ABORT, RTB, CLOSE; a `callforfire` thread (and POLAR,
 * SHIFT) ADD, DROP, LEFT, RIGHT, FFE, REPEAT, CHECK FIRE, EOM; `hlz` CONFIRM,
 * ALL IN, ABORT, RTB, CLOSE; `extract` CONFIRM, EXTRACT, ALL IN, ABORT, RTB,
 * CLOSE (2026-11-02); `casevac` and `airdrop` CONFIRM, ABORT, RTB, CLOSE; `onstation`
 * and `qrf` ABORT, RTB, CLOSE; `jump` BOARD (2026-11-02), ABORT, RTB, CLOSE;
 * `resupply` ABORT, CLOSE (QUICK_SUPPORT,
 * which also names EOM). Every support card has one (2026-11-02), and its
 * sender is never offered the asset's words - ROGER, WILCO, ON TASK, CANTCO
 * (jmfsb_support_fnc_assetCard) - on any row. The crew it went to, and any other
 * thread, keep
 * the registry's one-tap replies - those its card answers with, when it names
 * them (replyableWith; the deck's new support replies have no fields either,
 * and are not a SITREP's to offer) - and the player's own Quick replies.
 *
 * ONLY WHAT THE SERVER WOULD TAKE IS DRAWN (tablet review 2026-11-01, 3.1):
 * a card the deck lacks, one the thread's state refuses, or one only its
 * issuer, its assignee or a leader may send (EFUNC(messaging,srvThreadFor))
 * is not on the row. A card with no required line is filed in one press; one
 * with a required line (BDA) opens in the composer, on this thread.
 *
 * ADJUST IS FOUR TILES (doc 6.2): ADD, DROP, LEFT, RIGHT. A press opens the
 * distance pick on the row - 25 50 100 200 400 and BACK - and a distance files
 * `adjust` with the direction and the metres in that one press. The pick is
 * held per thread (GVAR(readerAdjust)), so it does not follow the player to
 * another one.
 *
 * THE THREAD'S CURRENT ORDER CHOOSES THE ROW (2026-11-09, docs/DESIGN_MESSAGE_
 * TEMPLATES.md): the support row is the one of the last tasking card filed in
 * the thread (EFUNC(messaging,currentOrder)) - an INSERTION after its PICKUP,
 * a CAS REQUEST filed into a TIC - and its sender is the one it is offered
 * to. A question's answers may be answer-only cards (HOT, COLD, CORRECT ...):
 * they are offered here, and only here (FUNC(threadLegal) argument 2).
 *
 * SEND SITREP ON A TIC THREAD (user, 2026-11-02: "after contact a sitrep
 * should be sent"): first on the row, for the TIC's sender and his squad
 * leader, while the thread is open and the deck has a SITREP card. It opens the
 * SITREP in the composer, in the thread (FUNC(sitrepAfterTic)). When the
 * sender's watch has found the contact over (FUNC(contactCheck)), the row's
 * label is CONTACT OVER? SEND SITREP, drawn in the accent.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: The thread's messages, root first <ARRAY>
 * 2: Template ids the thread will take now from this player (FUNC(threadLegal)) <ARRAY>
 *
 * Return Value:
 * 0: The row's label <STRING>
 * 1: Tiles, each [word, QUICK_FILE / QUICK_OPEN / QUICK_PICK / QUICK_BACK /
 *    QUICK_PHRASE / QUICK_SITREP / QUICK_TASK, card id, payload pairs -
 *    [direction] for a pick] <ARRAY>
 * 2: The distance pick is open - BACK takes the VOICE MSG slot <BOOL>
 * 3: The label is the CONTACT OVER? prompt - drawn in the accent <BOOL>
 *
 * Example:
 * ([_thread, _messages, _legal] call jmfsb_tacpad_fnc_readerQuickTiles) params ["_label", "_tiles", "_picking", "_alert"]
 *
 * Public: No
 */

params [["_thread", createHashMap, [createHashMap]], ["_messages", [], [[]]], ["_legal", [], [[]]]];

private _threadId = _thread getOrDefault ["id", ""];
private _rootId = _thread getOrDefault ["rootTemplateId", ""];
if (_rootId isEqualTo "") then {
    _rootId = (_messages param [0, createHashMap]) getOrDefault ["templateId", ""];
};

// THE SERVER'S SENDER RULE, as the thread carries it (EFUNC(messaging,srvThreadFor)).
private _myUid = getPlayerUID player;
private _isLeader = (player getVariable ["isLeader", false]) isEqualTo true;
private _issuer = _thread getOrDefault ["issuerUid", ""];
// The current order (2026-11-09): its card picks the row, its sender is the
// issuer the row is for (a CAS REQUEST filed into a TIC by another man).
([_messages] call EFUNC(messaging,currentOrder)) params ["_currentId", "", "_tasking"];
if (_currentId isNotEqualTo "" && _currentId isNotEqualTo _rootId) then {
    _rootId = _currentId;
    _issuer = _tasking getOrDefault ["fromUid", _issuer];
};
private _claimed = _thread getOrDefault ["claimedBy", ""];
private _fnc_may = {
    params ["_t"];
    switch (_t getOrDefault ["senderMustBe", "any"]) do {
        case "issuer": {_myUid isEqualTo _issuer};
        case "assignee": {_claimed in ["", _myUid]};
        case "leader": {_isLeader};
        default {true};
    }
};

// THE ISSUER OF A SUPPORT THREAD NEVER SPEAKS FOR THE ASSET (2026-11-02): a
// card only the asset sends (jmfsb_support_fnc_assetCard - ROGER, WILCO, ON
// TASK, CANTCO; not FFE, his observer's call) is never his tile, whatever row
// it would land on. ON TASK has no required line and anyone may send it while
// unclaimed, so pressed by him it moved his own request to IN_PROGRESS and
// the asset's ON TASK was never sent. FUNC(threadLegal) holds the same rule
// for every place a reply is offered; the server refuses it in an asset's
// thread.
private _supportIssuer = _myUid isEqualTo _issuer
    && (QUICK_SUPPORT findIf {(_x select 0) isEqualTo _rootId}) >= 0
    && !isNil QEFUNC(support,assetCard);

// A card the thread takes now, the deck has, and this player may send - or
// an empty map.
private _fnc_card = {
    params ["_id"];
    if !(_id in _legal) exitWith {createHashMap};
    private _t = [_id] call EFUNC(messaging,template);
    if (_t isEqualTo createHashMap) exitWith {createHashMap};
    if !([_t] call _fnc_may) exitWith {createHashMap};
    if (_supportIssuer && {[_id] call EFUNC(support,assetCard)}) exitWith {createHashMap};
    _t
};

private _dirKey = ([QUICK_ADJUST, QUICK_ADJUST_DIR_LINE] call EFUNC(messaging,fieldKeys)) param [0, ""];
private _distKey = ([QUICK_ADJUST, QUICK_ADJUST_DIST_LINE] call EFUNC(messaging,fieldKeys)) param [0, ""];
private _canAdjust = _dirKey isNotEqualTo "" && _distKey isNotEqualTo "";

private _result = [];

// ------------------------------------------------------ the distance pick ---
GVAR(readerAdjust) params [["_pickThread", "", [""]], ["_pickDir", "", [""]]];
if (_canAdjust && _pickThread isEqualTo _threadId && _pickDir isNotEqualTo "") then {
    private _adjust = [QUICK_ADJUST] call _fnc_card;
    if (_adjust isEqualTo createHashMap) exitWith {};
    // The metres are values: drawn untracked, as numbers.
    private _pick = QUICK_ADJUST_METRES apply {[str _x, QUICK_FILE, QUICK_ADJUST, [[_dirKey, _pickDir], [_distKey, _x]]]};
    _pick pushBack [QUICK_BACK_WORD, QUICK_BACK, "", []];
    _result = [format ["%1 %2", toUpper (_adjust getOrDefault ["short", QUICK_ADJUST]), _pickDir], _pick, true];
};
if (_result isNotEqualTo []) exitWith {_result};

// ---------------------------------------------- a row of cards, as tiles ---
private _rowAt = QUICK_SUPPORT findIf {(_x select 0) isEqualTo _rootId};
private _supportRow = [];
if (_rowAt >= 0) then {
    _supportRow = (QUICK_SUPPORT select _rowAt) select 1;
};
private _words = createHashMapFromArray _supportRow;
private _most = READER_TILES * READER_TILE_ROWS - 1;

private _fnc_row = {
    params ["_ids"];
    private _clean = (_ids apply {toLower (trim _x)}) select {_x isNotEqualTo ""};
    private _out = [];
    {
        private _id = _x;
        private _t = [_id] call _fnc_card;
        if (_t isEqualTo createHashMap) then {continue};

        if (_id isEqualTo QUICK_ADJUST && _canAdjust) then {
            {_out pushBack [_x, QUICK_PICK, QUICK_ADJUST, [_x]]} forEach QUICK_ADJUST_DIRS;
            continue;
        };

        private _word = _words getOrDefault [_id, ""];
        if (_word isEqualTo "") then {_word = toUpper (_t getOrDefault ["short", _id])};
        // A NEW TASK IN THE THREAD (2026-11-02): an answer that is a ROOT
        // card the asset takes there (CAS on FURTHER TASKING?, LIFT on HOLD,
        // RTB OR NEXT LIFT?) opens that card in the composer, in this thread.
        if ((_t getOrDefault ["kind", QUICK_KIND_REPLY]) isEqualTo QUICK_KIND_ROOT) then {
            _out pushBack [_word, QUICK_TASK, _id, []];
            continue;
        };
        private _required = ((values (_t getOrDefault ["fields", createHashMap])) findIf {
            (_x getOrDefault ["required", false]) isEqualTo true
        }) >= 0;
        _out pushBack [_word, [QUICK_FILE, QUICK_OPEN] select _required, _id, []];
    } forEach (_clean arrayIntersect _clean);
    if (count _out > _most) then {_out resize _most};
    _out
};

// --------------------------------------------- what the asset just asked ---
private _newest = _messages param [(count _messages) - 1, createHashMap];
private _isPrompt = count _messages > 1 && (_newest getOrDefault ["templateId", ""]) isEqualTo QUICK_PROMPT;
if (_isPrompt) then {
    private _key = ([QUICK_PROMPT, QUICK_PROMPT_ANSWERS] call EFUNC(messaging,fieldKeys)) param [0, ""];
    private _answers = (createHashMapFromArray (_newest getOrDefault ["payload", []])) getOrDefault [_key, ""];
    if !(_answers isEqualType "") exitWith {};
    // The answer-only cards are this question's to offer (2026-11-09) - the
    // rows after it go back to the thread's own list.
    private _general = _legal;
    _legal = [_threadId, _thread, true] call FUNC(threadLegal);
    private _tiles = [_answers splitString QUICK_ANSWER_SEP] call _fnc_row;
    _legal = _general;
    if (_tiles isEqualTo []) exitWith {};
    _result = ["QUICK REPLY", _tiles, false];
};
if (_result isNotEqualTo []) exitWith {_result};

// ---------------------------------------------- the support card's row ---
// The sender's (doc 6.2): the player crew a `cas` went to answers it as any
// thread, ROGER and WILCO.
if (_supportRow isNotEqualTo [] && _myUid isEqualTo _issuer) exitWith {
    ["QUICK REPLY", [_supportRow apply {_x select 0}] call _fnc_row, false]
};

// ------------------------------------------------- every other thread ---
// The registry's one-tap replies, as many as the row has before VOICE MSG. A
// template only a leader may send is not offered to anyone else - the
// picker's rule. ONE TAP IS A REPLY CARD WITH NOTHING REQUIRED (report-card
// review, 2026-11-02): the deck's WILCO and ON TASK carry an optional DETAIL
// line now and were dropped by the old "no fields" rule; a report that can
// also be a reply (SITREP, MIST) is not a tap.
private _rootCard = [_rootId] call EFUNC(messaging,template);
private _answersWith = _rootCard getOrDefault ["replyableWith", []];
private _tiles = [];

// SEND SITREP, first, on an open TIC thread: to its sender, and to his squad
// leader (the leader of a group the sender is in).
private _sitrepFor = false;
if (_legal isNotEqualTo [] && (_rootCard getOrDefault ["broadcast", ""]) isEqualTo CONTACT_BROADCAST) then {
    private _lead = leader (group player) isEqualTo player
        && {((units group player) findIf {getPlayerUID _x isEqualTo _issuer}) >= 0};
    _sitrepFor = (_myUid isEqualTo _issuer || _lead)
        && {([SITREP_CARD] call EFUNC(messaging,template)) isNotEqualTo createHashMap};
};
if (_sitrepFor) then {_tiles pushBack [SITREP_TILE_WORD, QUICK_SITREP, SITREP_CARD, []]};
private _prompted = _sitrepFor && GVAR(contactPrompted) && GVAR(contactThread) isEqualTo _threadId;
{
    if (_answersWith isNotEqualTo [] && !(_x in _answersWith)) then {continue};
    private _t = [_x] call _fnc_card;
    if (_t isEqualTo createHashMap) then {continue};
    if ((_t getOrDefault ["kind", ""]) isNotEqualTo QUICK_KIND_REPLY) then {continue};
    private _needs = ((values (_t getOrDefault ["fields", createHashMap])) findIf {
        (_x getOrDefault ["required", false]) isEqualTo true
    }) >= 0;
    if (_needs) then {continue};
    _tiles pushBack [toUpper (_t getOrDefault ["short", _x]), QUICK_FILE, _x, []];
} forEach (["reply"] call EFUNC(messaging,templateIds));

// The player's phrases into what is left. A template id already on the row is
// not repeated; one the thread will not take is not sent as words either.
private _known = missionNamespace getVariable [QEGVAR(messaging,templateIds), []];
private _free = "freetext" in _legal;
{
    private _entry = trim _x;
    private _id = toLower _entry;
    if (_entry isEqualTo "" || {(_tiles findIf {(_x select 2) isEqualTo _id}) >= 0}) then {continue};
    if (_id in _known) then {
        private _t = [_id] call _fnc_card;
        if (_t isNotEqualTo createHashMap) then {
            _tiles pushBack [toUpper (_t getOrDefault ["short", _entry]), QUICK_FILE, _id, []];
        };
        continue;
    };
    if (_free) then {_tiles pushBack [toUpper _entry, QUICK_PHRASE, "", []]};
} forEach (GVAR(quickReplies) splitString ",");

if (count _tiles > READER_TILES - 1) then {_tiles resize (READER_TILES - 1)};

[["QUICK REPLY", CONTACT_PROMPT] select _prompted, _tiles, false, _prompted]
