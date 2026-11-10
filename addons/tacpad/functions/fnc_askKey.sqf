#include "script_component.hpp"
/*
 * Author: YonV
 * A device key pressed while the walking view shows a question (user,
 * 2026-11-06: "the 6-9 are for fast replys with out opening the tablet"):
 * F1-F4 (numpad 6-9) pick the answer on that key of the page; LEFT / RIGHT
 * (numpad 0 / .) page back and on. From jmfsb_devices_fnc_overlayButton.
 *
 * - An answer with nothing to fill is filed into the thread in that press, as
 *   the tablet's quick tile files it (EFUNC(messaging,submit)); the strip reads
 *   SENT until the answer comes back and takes the question down
 *   (FUNC(askTraffic)), or until the next question.
 * - One with a line to fill (BDA, DESTINATION) opens in the composer on the
 *   thread; a new task in the thread (CAS, LIFT) the same way
 *   (FUNC(taskInThread)) - the tablet is the only place to type.
 * - ADJUST's direction opens the distance pick; BACK closes it.
 * - A crew's question is filed as the `prompt` card (or its own card - SHOT,
 *   IN) into the request's thread.
 * - A local choice runs its code (FUNC(askChoice)).
 *
 * Arguments:
 * 0: Key, 0-5 in printed order F1 F2 F3 F4 LEFT RIGHT <NUMBER>
 *
 * Return Value:
 * Handled - the key is consumed <BOOL>
 *
 * Example:
 * [0] call jmfsb_tacpad_fnc_askKey
 *
 * Public: No
 */

params [["_key", -1, [0]]];

([] call FUNC(askCurrent)) params ["_id", "_ask"];
if (_id isEqualTo "") exitWith {false};
private _items = [_id, _ask] call FUNC(askItems);
if (_items isEqualTo []) exitWith {false};

// THE ARROWS PAGE - only with more than one page; else they are the player's
// own keys as ever (the active net left / right).
private _pages = ceil ((count _items) / ASK_KEYS) max 1;
if (_key >= ASK_KEYS) exitWith {
    if (_pages < 2) exitWith {false};
    GVAR(askPage) = ((GVAR(askPage) + ([-1, 1] select (_key > ASK_KEYS))) + _pages) mod _pages;
    [] call FUNC(askChanged);
    true
};

// An empty key on the page is still the strip's: a press there must not
// fall through to the voice key it is bound to under the strip.
private _item = _items param [GVAR(askPage) * ASK_KEYS + _key, []];
if (_item isEqualTo []) exitWith {true};
_item params ["_word", "_act", "_cardId", "_payload"];

switch (_act) do {
    case ASK_LOCAL_ACT: {
        private _code = _ask getOrDefault ["code", {}];
        private _args = _ask getOrDefault ["args", []];
        GVAR(asks) deleteAt _id;
        [GVAR(askPage) * ASK_KEYS + _key, _word, _args] call _code;
    };
    case QUICK_PICK: {
        GVAR(askPick) = [_id, _payload param [0, ""]];
        GVAR(askPage) = 0;
    };
    case QUICK_BACK: {
        GVAR(askPick) = [];
        GVAR(askPage) = 0;
    };
    case QUICK_OPEN: {
        [_id, _cardId] call FUNC(composeOpen);
    };
    case QUICK_TASK: {
        [_id, _cardId] call FUNC(taskInThread);
    };
    default {
        // QUICK_FILE and a crew's question: filed into the thread now.
        [_cardId, _payload, [], _id] call EFUNC(messaging,submit);
        GVAR(askSent) = [_id, _word, CBA_missionTime];
        if (_act isEqualTo QUICK_FILE) then {GVAR(askPick) = []};
    };
};
[] call FUNC(askChanged);
true
