#include "script_component.hpp"
/*
 * Author: YonV
 * Messaging's onReceive hook for the phone's quick answers (user, 2026-11-06):
 * every message that arrives for this player, read for the questions it puts
 * to him and the ones it settles.
 *
 * - AN ASSET'S QUESTION: a `prompt` card with answers that this player did not
 *   send himself (his own traffic arrives already read by him; an AI asset's
 *   is filed under his uid but unread) - FUNC(askLocal). A human crew's
 *   question is the same card, so it is caught the same way.
 * - ANSWERED: one of the question's answers arrives in its thread - whoever
 *   sent it, from the phone, the tablet or the ACE action's server side.
 * - OVER: the thread's row says CLOSED, ABORTED or DECLINED.
 * - A CREW'S REQUEST: a support card's root, addressed to this player's own
 *   box (P:<uid>) by someone else - he is the crew it went to, and the keys
 *   offer him that type's questions while nothing waits for him
 *   (ASK_CREW_QUESTIONS, FUNC(askView)).
 *
 * Arguments:
 * 0: Message <HASHMAP>
 * 1: Index entry <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_message, _entry] call jmfsb_tacpad_fnc_askTraffic
 *
 * Public: No
 */

params [["_message", createHashMap, [createHashMap]], ["_entry", createHashMap, [createHashMap]]];

if (isNil QEFUNC(messaging,fieldKeys)) exitWith {};

private _threadId = _entry getOrDefault ["threadId", _message getOrDefault ["threadId", ""]];
if (!(_threadId isEqualType "") || _threadId isEqualTo "") exitWith {};

if ((_entry getOrDefault ["status", ""]) in ASK_OVER_STATES) exitWith {
    private _had = _threadId in GVAR(asks) || {_threadId in GVAR(askCrew)};
    GVAR(asks) deleteAt _threadId;
    GVAR(askCrew) deleteAt _threadId;
    if (_had) then {[] call FUNC(askChanged)};
};

private _myUid = getPlayerUID player;
private _mine = _myUid in (_message getOrDefault ["readBy", []]);
private _cardId = _message getOrDefault ["templateId", ""];
private _rootId = _entry getOrDefault ["templateId", ""];
private _payload = createHashMapFromArray (_message getOrDefault ["payload", []]);

// ------------------------------------------------------------ a question ---
if (_cardId isEqualTo QUICK_PROMPT) exitWith {
    if (_mine) exitWith {};
    private _textKey = ([QUICK_PROMPT, QUICK_PROMPT_TEXT] call EFUNC(messaging,fieldKeys)) param [0, ""];
    private _answerKey = ([QUICK_PROMPT, QUICK_PROMPT_ANSWERS] call EFUNC(messaging,fieldKeys)) param [0, ""];
    private _text = _payload getOrDefault [_textKey, ""];
    private _answers = _payload getOrDefault [_answerKey, ""];
    if (!(_text isEqualType "") || {!(_answers isEqualType "")}) exitWith {};
    // A question with no answers (POP SMOKE) is told by the notification; with
    // nothing to key, it does not hold the keys.
    if ((trim _answers) isEqualTo "") exitWith {};
    private _flash = (_message getOrDefault ["priority", _entry getOrDefault ["priority", ""]]) isEqualTo CARD_PRIORITY_HIGH;
    [_threadId, _text, _answers, _message getOrDefault ["fromCallsign", ""], _flash, _rootId] call FUNC(askLocal);
};

// ------------------------------------------------------------- answered ---
private _ask = GVAR(asks) getOrDefault [_threadId, createHashMap];
if (_ask isNotEqualTo createHashMap && {_cardId in (_ask getOrDefault ["answers", []])}) then {
    GVAR(asks) deleteAt _threadId;
    if ((GVAR(askPick) param [0, ""]) isEqualTo _threadId) then {GVAR(askPick) = []};
    [] call FUNC(askChanged);
};

// ----------------------------------------------------- a crew's request ---
if (_mine || {(_message getOrDefault ["seq", -1]) isNotEqualTo 0}) exitWith {};
if ((_entry getOrDefault ["boxId", ""]) isNotEqualTo format ["P:%1", _myUid]) exitWith {};
if ((ASK_CREW_QUESTIONS findIf {_cardId in (_x select 0)}) < 0) exitWith {};
GVAR(askCrew) set [_threadId, createHashMapFromArray [
    ["kind", ASK_MODE_CREW],
    ["rootId", _cardId],
    ["who", _message getOrDefault ["fromCallsign", ""]],
    ["at", CBA_missionTime]
]];
[] call FUNC(askChanged);
