#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a choice of this machine's own on the walking view's quick-answer
 * strip - numpad 6-9 pick, 0 / . page - beside the support questions
 * (FUNC(askView), FUNC(askKey)). For a question that is not a message: the
 * ECOTI building mark's colour (user, 2026-11-06: "the color when the keybind
 * is pressed need a 6-9 question on color"). A pick calls the code with
 * [index picked, its word, args] and takes the choice down; the choice also
 * goes after its timeout, or when the same id is asked again or dropped.
 *
 * Arguments:
 * 0: Id - one choice per id; "" words drop it <STRING>
 * 1: What is asked <STRING>
 * 2: The words, one per key <ARRAY of STRINGs>
 * 3: Code, run with [index, word, args] <CODE>
 * 4: Args <ANY> (optional, default [])
 * 5: Seconds before it goes unanswered, 0 never <NUMBER> (optional, default 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ecoti", "MARK COLOUR", ["RED", "BLUE"], {systemChat str _this}] call jmfsb_tacpad_fnc_askChoice
 *
 * Public: Yes
 */

params [
    ["_id", "", [""]],
    ["_text", "", [""]],
    ["_words", [], [[]]],
    ["_code", {}, [{}]],
    ["_args", []],
    ["_timeout", 0, [0]]
];

if (!hasInterface || _id isEqualTo "" || isRemoteExecuted) exitWith {};

private _key = format ["%1%2", ASK_LOCAL_PREFIX, _id];
if (_words isEqualTo [] || {_code isEqualTo {}}) exitWith {
    if (_key in GVAR(asks)) then {
        GVAR(asks) deleteAt _key;
        [] call FUNC(askChanged);
    };
};

GVAR(asks) set [_key, createHashMapFromArray [
    ["kind", ASK_MODE_LOCAL],
    ["text", _text],
    ["who", ""],
    // Asked on purpose by this player a moment ago: it comes first.
    ["flash", true],
    ["at", CBA_missionTime],
    ["until", [0, CBA_missionTime + _timeout] select (_timeout > 0)],
    ["words", (_words select {_x isEqualType ""}) apply {toUpper _x}],
    ["code", _code],
    ["args", _args]
]];
[] call FUNC(askChanged);
