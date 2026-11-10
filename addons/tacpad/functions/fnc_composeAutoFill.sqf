#include "script_component.hpp"
/*
 * Author: YonV
 * Fills the card's autofill fields from what the game knows (report-card
 * review, user 2026-11-02, decision 5: "build the autofill sources the review
 * lists ... as composer autofills"). Called by FUNC(composeCard) before every
 * draw, so a field that follows something - the thread's point, the vehicle
 * the sender is in - follows it as it changes.
 *
 * THE PLAYER'S ANSWER STANDS. A field still holding what it was last given
 * follows its source; one he typed over, ticked or picked otherwise is his,
 * and is left. A field is written only when its source's answer changes, so a
 * tick he moved is not put back on the next press. What was given is kept in
 * the answer map itself (AUTO_STATE_KEY), so every new card - and every card
 * a refusal puts back - carries its own.
 *
 * A STATE WORD (GREEN / YELLOW / RED / BLACK) becomes the tick whose word it
 * is on a line of ticks (DEFREP) and the pick of it on a choice (SITREP's
 * STATUS, where YELLOW reads AMBER); ticking one of an exclusive set unticks
 * the others. A position is shown as its grid, as CUR LOC shows one.
 *
 * ownCallsign, missionTime and pac: are not here: FUNC(composeCard) shows
 * them in their box, as before.
 *
 * Arguments:
 * 0: The card's id <STRING>
 * 1: The answers <HASHMAP> - changed in place
 * 2: The grids shown for positions <HASHMAP> - changed in place
 * 3: The thread being answered, "" for a new message <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [GVAR(composeTemplate), GVAR(composeValues), GVAR(composeGridText), GVAR(composeThread)] call jmfsb_tacpad_fnc_composeAutoFill
 *
 * Public: No
 */

params [
    ["_templateId", "", [""]],
    ["_values", createHashMap, [createHashMap]],
    ["_grids", createHashMap, [createHashMap]],
    ["_threadId", "", [""]]
];

if (_templateId isEqualTo "") exitWith {};

private _template = [_templateId] call EFUNC(messaging,template);
private _fields = _template getOrDefault ["fields", createHashMap];
private _order = _template getOrDefault ["order", []];

private _state = _values getOrDefault [AUTO_STATE_KEY, createHashMap];
if ((_state getOrDefault [AUTO_STATE_CARD, ""]) isNotEqualTo _templateId) then {
    _state = createHashMapFromArray [[AUTO_STATE_CARD, _templateId]];
    _values set [AUTO_STATE_KEY, _state];
};

// An answer as the words it reads as: a number a box gave back as text is the
// number it was given, and an unticked box is no answer.
private _fnc_said = {
    params ["_value"];
    if (_value isEqualTo false) exitWith {""};
    if (_value isEqualType "") exitWith {trim _value};
    str _value
};

// A state word as this field takes it: true on the tick that is the word, the
// pick that is the word (or its other spelling), "" where there is none.
private _fnc_word = {
    params ["_word", "_field", "_type"];
    private _words = [_word];
    private _alias = AUTO_COLOUR_ALIASES findIf {(_x select 0) isEqualTo _word};
    if (_alias >= 0) then {_words pushBack ((AUTO_COLOUR_ALIASES select _alias) select 1)};
    if (_type isEqualTo "bool") exitWith {
        (toUpper (trim (_field getOrDefault ["prefix", ""]))) in _words
    };
    private _choices = _field getOrDefault ["choices", []];
    private _at = _choices findIf {_x in _words};
    if (_at < 0) exitWith {""};
    _choices select _at
};

{
    private _key = _x;
    private _field = _fields getOrDefault [_key, createHashMap];
    private _source = _field getOrDefault ["autoFill", "none"];
    if !(_source isEqualType "") then {continue};
    if !(((_source splitString AUTO_SEP) param [0, ""]) in AUTO_SOURCES) then {continue};

    private _type = _field getOrDefault ["type", "text"];
    private _value = [_source, _threadId] call FUNC(autoValue);
    if (_value isEqualType "" && _type in AUTO_WORD_TYPES) then {
        _value = [_value, _field, _type] call _fnc_word;
    };
    if (_value isEqualTo false) then {_value = ""};

    // Nothing new from the source: nothing to do.
    private _had = _key in _state;
    private _given = _state getOrDefault [_key, ""];
    if (_had && _value isEqualTo _given) then {continue};
    _state set [_key, _value];

    // His own answer stands.
    private _now = [_values getOrDefault [_key, ""]] call _fnc_said;
    private _untouched = _now isEqualTo "";
    if (!_untouched && _had) then {
        _untouched = _now isEqualTo ([_given] call _fnc_said);
    };
    if (!_untouched) then {continue};

    if (_value isEqualTo "" || _value isEqualTo []) then {
        _values deleteAt _key;
        _grids deleteAt _key;
        continue;
    };

    _values set [_key, _value];
    if (_value isEqualType []) then {
        _grids set [_key, mapGridPosition _value];
    } else {
        _grids deleteAt _key;
    };

    // A tick of an exclusive set: the others in it are off.
    private _set = _field getOrDefault ["exclusive", ""];
    if (_value isEqualTo true && _set isNotEqualTo "") then {
        {
            if (_x isEqualTo _key) then {continue};
            if (((_fields getOrDefault [_x, createHashMap]) getOrDefault ["exclusive", ""]) isEqualTo _set) then {
                _values deleteAt _x;
            };
        } forEach _order;
    };
} forEach _order;
