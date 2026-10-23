#include "script_component.hpp"
/*
    File: fnc_questionsLoad.sqf
    Author: YonV
    Description: The application questions, in order - the website's
        jmfsbd_questions: <unit>.web.questions, items keyed by id with
        {label, type, required, help, options, order}, turned into an
        ordered list of hashmaps each carrying its id. Server only,
        scheduled; read once into GVAR(docCache) and published as
        GVAR(applyQuestions) for the tacpad's APPLICATION tab.

        With no stored questions the website asks its standard set
        (GHOSTD_DEFAULT_QUESTIONS in DIVINER_Web src/applications.php), so
        the game asks the same one - keep the two lists in step.

        A "skills" question (user, 2026-10-19: "what do you want to be") is
        given "choices" - [[skill id, display name], ...] off the unit's
        skills (<unit>.skills, GVAR(structure)) - so the tile can draw a
        checkbox each without the structure, and an admin page can name
        the ids that were ticked.

    Parameters:
        0: Read the database again <BOOL> (optional)

    Returns:
        The questions <ARRAY of HASHMAP>
*/

params [["_fresh", false, [false]]];

if (!isServer) exitWith {[]};
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _key = _unit + ".web.questions";
if (isNil QGVAR(docCache)) then {GVAR(docCache) = createHashMap};
if (_fresh) then {GVAR(docCache) deleteAt _key};

private _doc = GVAR(docCache) get _key;
if (isNil "_doc") then {
    ([_key] call FUNC(svcLoad)) params ["_d", "_s"];
    _doc = [createHashMap, _d] select (_s isEqualTo "ok");
    if (_s isEqualTo "ok") then {GVAR(docCache) set [_key, _d]};
};

private _items = _doc getOrDefault ["items", []];
private _out = [];
if (_items isEqualType createHashMap) then {
    {
        private _q = +_y;
        if (_q isEqualType createHashMap) then {
            _q set ["id", _x];
            _out pushBack _q;
        };
    } forEach _items;
    {_x set ["_ord", format ["%1", 1000000 + (_x getOrDefault ["order", 0])]]} forEach _out;
    _out = [_out, "_ord", true] call FUNC(docsSort);
    {_x deleteAt "_ord"} forEach _out;
} else {
    if (_items isEqualType []) then {_out = _items select {_x isEqualType createHashMap}};
};

// the website's standard set, in its order, when the unit has stored none
if (_out isEqualTo []) then {
    private _order = 0;
    _out = [
        ["callsign", "What should we call you?", "text", true, "The name you go by in game.", []],
        ["age", "Age", "text", false, "Optional. Some units have a minimum; say if you would rather not.", []],
        ["timezone", "Country or timezone", "text", true, "So we know whether our operation times work for you.", []],
        ["experience", "Arma experience", "textarea", true, "Roughly how many hours, and what you have mostly played - co-op, PvP, editor, modding. Never having played is a fine answer.", []],
        ["milsim", "Milsim experience", "textarea", false, "Units you have served with, and roles you have held. Leave empty if this would be your first.", []],
        ["mic", "Working microphone?", "select", true, "", ["Yes", "No", "Not yet, but I can get one"]],
        ["availability", "When can you play?", "text", false, "Which evenings, roughly.", []],
        ["why", "Why us?", "textarea", false, "Optional. What you are looking for in a unit.", []],
        ["heard", "How did you hear about us?", "text", false, "", []],
        ["interests", "What do you want to be (when you do not grow up)?", "skills", false, "", []]
    ] apply {
        _x params ["_id", "_label", "_type", "_required", "_help", "_options"];
        _order = _order + QUESTION_ORDER_STEP;
        createHashMapFromArray [
            ["id", _id], ["label", _label], ["type", _type], ["required", _required],
            ["help", _help], ["options", _options], ["order", _order]
        ]
    };
};

// every skill the unit has, by display name, for the "skills" questions
private _skills = GVAR(structure) getOrDefault ["skills", createHashMap];
private _choices = [];
if (_skills isEqualType createHashMap) then {
    _choices = (keys _skills) apply {
        private _s = _skills get _x;
        private _name = if (_s isEqualType createHashMap) then {_s getOrDefault ["name", _x]} else {_x};
        [[_name, str _name] select !(_name isEqualType ""), _x]
    };
    _choices sort true;
    _choices = _choices apply {[_x # 1, _x # 0]};
};
{
    if ((toLower (_x getOrDefault ["type", "text"])) isEqualTo "skills") then {_x set ["choices", +_choices]};
} forEach _out;

GVAR(applyQuestions) = _out;
publicVariable QGVAR(applyQuestions);
_out
