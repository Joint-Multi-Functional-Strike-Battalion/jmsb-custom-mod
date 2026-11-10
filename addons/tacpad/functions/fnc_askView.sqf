#include "script_component.hpp"
/*
 * Author: YonV
 * What the walking view's quick-answer strip shows (user, 2026-11-06): who
 * asks and what, the page of answers on the device keys F1-F4 (numpad 6-9),
 * which page of how many, and which question of how many waiting. Read every
 * draw; the devices format it with the keys as the player has them bound.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The strip, an empty map when nothing is on the keys <HASHMAP>:
 *   mode   ASK_MODE_ANSWER, ASK_MODE_CREW or ASK_MODE_LOCAL
 *   who    the call sign asking, or the requester a crew asks
 *   text   what is asked ("" for a crew's list)
 *   flash  FLASH <BOOL>
 *   n, of  this question's place and how many wait (0, n for a crew's list)
 *   page, pages
 *   words  ASK_KEYS words, "" for an empty key
 *   sent   the word last pressed while it still waits, else ""
 *
 * Example:
 * private _view = [] call jmfsb_tacpad_fnc_askView
 *
 * Public: No
 */

([] call FUNC(askCurrent)) params ["_id", "_ask", "_n", "_of"];
if (_id isEqualTo "") exitWith {createHashMap};

private _items = [_id, _ask] call FUNC(askItems);
if (_items isEqualTo []) exitWith {createHashMap};

private _pages = ceil ((count _items) / ASK_KEYS) max 1;
GVAR(askPage) = GVAR(askPage) max 0 min (_pages - 1);
private _words = (_items select [GVAR(askPage) * ASK_KEYS, ASK_KEYS]) apply {_x select 0};
while {count _words < ASK_KEYS} do {_words pushBack ""};

GVAR(askSent) params [["_sentId", "", [""]], ["_sentWord", "", [""]], ["_sentAt", 0, [0]]];
private _sent = ["", _sentWord] select (_sentId isEqualTo _id && {CBA_missionTime - _sentAt < ASK_SENT_S});

createHashMapFromArray [
    ["mode", _ask getOrDefault ["kind", ASK_MODE_ANSWER]],
    ["who", _ask getOrDefault ["who", ""]],
    ["text", _ask getOrDefault ["text", ""]],
    ["flash", _ask getOrDefault ["flash", false]],
    ["n", _n],
    ["of", _of],
    ["page", GVAR(askPage) + 1],
    ["pages", _pages],
    ["words", _words],
    ["sent", _sent]
]
