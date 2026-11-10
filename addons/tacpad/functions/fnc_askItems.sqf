#include "script_component.hpp"
/*
 * Author: YonV
 * What the keys do for one question on the walking view (user, 2026-11-06):
 * every choice it offers, in order, ASK_KEYS a page (FUNC(askView),
 * FUNC(askKey)).
 *
 * - AN ASSET'S QUESTION: its answers, as the tablet's quick tiles read them
 *   (FUNC(readerQuickTiles)): the support row's word where it names one, else
 *   the card's short name; a card with a required line (BDA, DESTINATION)
 *   opens in the composer on the thread; a root card (CAS on FURTHER
 *   TASKING?) opens as a new task in the thread; ADJUST is ADD, DROP, LEFT,
 *   RIGHT, and one of them the distance pick - 25 to 400 m and BACK.
 * - A CREW'S QUESTIONS: ASK_CREW_QUESTIONS for the card it was sent.
 * - A LOCAL CHOICE: its words (FUNC(askChoice)).
 *
 * Arguments:
 * 0: Id - thread id or local key <STRING>
 * 1: Question <HASHMAP>
 *
 * Return Value:
 * Items, each [word, act, card id, payload pairs] <ARRAY>
 *
 * Example:
 * private _items = [_id, _ask] call jmfsb_tacpad_fnc_askItems
 *
 * Public: No
 */

params [["_id", "", [""]], ["_ask", createHashMap, [createHashMap]]];

private _kind = _ask getOrDefault ["kind", ""];

if (_kind isEqualTo ASK_MODE_LOCAL) exitWith {
    (_ask getOrDefault ["words", []]) apply {[_x, ASK_LOCAL_ACT, "", []]}
};

if (isNil QEFUNC(messaging,template)) exitWith {[]};
private _rootId = _ask getOrDefault ["rootId", ""];

if (_kind isEqualTo ASK_MODE_CREW) exitWith {
    private _at = ASK_CREW_QUESTIONS findIf {_rootId in (_x select 0)};
    if (_at < 0) exitWith {[]};
    private _textKey = ([QUICK_PROMPT, QUICK_PROMPT_TEXT] call EFUNC(messaging,fieldKeys)) param [0, ""];
    private _answerKey = ([QUICK_PROMPT, QUICK_PROMPT_ANSWERS] call EFUNC(messaging,fieldKeys)) param [0, ""];
    ((ASK_CREW_QUESTIONS select _at) select 1) apply {
        _x params ["_word", "_text", "_answers", "_card"];
        if (_card isEqualTo "") then {
            [_word, ASK_CREW_ACT, QUICK_PROMPT, [[_textKey, _text], [_answerKey, _answers]]]
        } else {
            [_word, ASK_CREW_ACT, _card, []]
        }
    }
};

// ------------------------------------------------- an asset's question ---
private _dirKey = ([QUICK_ADJUST, QUICK_ADJUST_DIR_LINE] call EFUNC(messaging,fieldKeys)) param [0, ""];
private _distKey = ([QUICK_ADJUST, QUICK_ADJUST_DIST_LINE] call EFUNC(messaging,fieldKeys)) param [0, ""];
private _canAdjust = _dirKey isNotEqualTo "" && _distKey isNotEqualTo "";

GVAR(askPick) params [["_pickId", "", [""]], ["_pickDir", "", [""]]];
if (_canAdjust && _pickId isEqualTo _id && _pickDir isNotEqualTo "") exitWith {
    private _pick = QUICK_ADJUST_METRES apply {[format ["%1 %2", _pickDir, _x], QUICK_FILE, QUICK_ADJUST, [[_dirKey, _pickDir], [_distKey, _x]]]};
    _pick pushBack [QUICK_BACK_WORD, QUICK_BACK, "", []];
    _pick
};

private _rowAt = QUICK_SUPPORT findIf {(_x select 0) isEqualTo _rootId};
private _words = createHashMapFromArray ([[], (QUICK_SUPPORT select _rowAt) select 1] select (_rowAt >= 0));

private _out = [];
{
    private _cardId = _x;
    private _t = [_cardId] call EFUNC(messaging,template);
    if (_t isEqualTo createHashMap) then {continue};
    if (_cardId isEqualTo QUICK_ADJUST && _canAdjust) then {
        {_out pushBack [_x, QUICK_PICK, QUICK_ADJUST, [_x]]} forEach QUICK_ADJUST_DIRS;
        continue;
    };
    private _word = _words getOrDefault [_cardId, ""];
    if (_word isEqualTo "") then {_word = toUpper (_t getOrDefault ["short", _cardId])};
    if ((_t getOrDefault ["kind", QUICK_KIND_REPLY]) isEqualTo QUICK_KIND_ROOT) then {
        _out pushBack [_word, QUICK_TASK, _cardId, []];
        continue;
    };
    private _required = ((values (_t getOrDefault ["fields", createHashMap])) findIf {
        (_x getOrDefault ["required", false]) isEqualTo true
    }) >= 0;
    _out pushBack [_word, [QUICK_FILE, QUICK_OPEN] select _required, _cardId, []];
} forEach (_ask getOrDefault ["answers", []]);

_out
