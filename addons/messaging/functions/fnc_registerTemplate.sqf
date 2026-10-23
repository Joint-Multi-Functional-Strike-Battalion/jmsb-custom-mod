#include "script_component.hpp"
/*
 * Author: JMSB
 * Registers a message template. Runs in preInit on every machine, so the
 * registry is identical everywhere and a message can be rendered without
 * asking the server what shape it is.
 *
 * FIELD KEYS ARE GENERATED FROM THE LINE TITLE, not from the field's label.
 * That is deliberate and it is a contract: the ALiVE forwarder maps a SALUTE
 * report by its S/A/L/U/T/E/R line titles and a SITREP by Callsign/Location/
 * Enemy/Friendly/Civ/Status/Remarks. Rename a line title and you have renamed
 * a field key. Rename a field's label and nothing breaks.
 *
 * A line with no title falls back to its position, so CALL FOR FIRE's unnamed
 * lines get L9.A, L10.A and so on rather than colliding on "".
 *
 * Arguments:
 * 0: Template id, lowercase, no spaces <STRING>
 * 1: Title as shown to the player <STRING>
 * 2: Short title, used in subjects and notifications <STRING>
 * 3: Lines <ARRAY> - each ["line title", "LINE LABEL", [field, field, ...]]
 *      field: ["prefix", "hint", "type"] or ["prefix", "hint", "type", options]
 * 4: Options <ARRAY> - [key, value] pairs, all optional (optional, default [])
 *
 * Return Value:
 * Template id, "" if it was rejected <STRING>
 *
 * Example:
 * ["mist", "MIST", "MIST", _lines] call jmfsb_messaging_fnc_registerTemplate
 *
 * Public: Yes
 */

params [
    ["_id", "", [""]],
    ["_title", "", [""]],
    ["_short", "", [""]],
    ["_lines", [], [[]]],
    ["_options", [], [[]]]
];

if (_id == "" || _title == "") exitWith {
    ERROR_1("template rejected - id and title are both required (id '%1')",_id);
    ""
};

if (_id in GVAR(templateIds)) exitWith {
    ERROR_1("template '%1' registered twice - the second one is ignored",_id);
    ""
};

private _opt = createHashMapFromArray _options;

private _template = createHashMapFromArray [
    ["id", _id],
    ["title", _title],
    ["short", [_short, _title] select (_short == "")],
    ["kind", _opt getOrDefault ["kind", "root"]],
    ["priority", _opt getOrDefault ["priority", "normal"]],
    ["subject", _opt getOrDefault ["subject", ""]],
    ["replyableWith", _opt getOrDefault ["replyableWith", []]],
    ["transitionsTo", _opt getOrDefault ["transitionsTo", ""]],
    ["allowedFrom", _opt getOrDefault ["allowedFrom", []]],
    ["senderMustBe", _opt getOrDefault ["senderMustBe", "any"]],
    ["reportable", _opt getOrDefault ["reportable", ""]],
    ["broadcast", _opt getOrDefault ["broadcast", ""]],
    ["routing", _opt getOrDefault ["routing", ""]],
    ["anchor", _opt getOrDefault ["anchor", ""]]
];

private _letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"];
private _built = [];
private _fields = createHashMap;
private _order = [];

{
    _x params [["_lineTitle", "", [""]], ["_lineLabel", "", [""]], ["_lineFields", [], [[]]]];

    private _lineKey = _lineTitle regexReplace ["\s+", ""];
    if (_lineKey == "") then {
        _lineKey = format ["L%1", _forEachIndex];
    };

    private _lineIndex = _forEachIndex;
    private _builtFields = [];

    {
        _x params [["_prefix", "", [""]], ["_hint", "", [""]], ["_type", "text", [""]], ["_fieldOpts", [], [[]]]];

        private _fo = createHashMapFromArray _fieldOpts;
        private _key = format ["%1.%2", _lineKey, _letters param [_forEachIndex, str _forEachIndex]];

        private _field = createHashMapFromArray [
            ["key", _key],
            ["line", _lineKey],
            ["lineLabel", _lineLabel],
            ["prefix", _prefix],
            ["hint", _hint],
            ["type", _type],
            ["required", _fo getOrDefault ["required", false]],
            ["exclusive", _fo getOrDefault ["exclusive", ""]],
            ["choices", _fo getOrDefault ["choices", []]],
            ["min", _fo getOrDefault ["min", -1e10]],
            ["max", _fo getOrDefault ["max", 1e10]],
            ["autoFill", _fo getOrDefault ["autoFill", "none"]],
            ["source", _fo getOrDefault ["source", "manual"]],
            // A grid field that must not offer CURRENT LOC - an ingress or an
            // egress is never where the sender is standing, and one press on
            // the wrong cell would say it was.
            ["noCur", _fo getOrDefault ["noCur", false]]
        ];

        _fields set [_key, _field];
        _order pushBack _key;
        _builtFields pushBack _field;
    } forEach _lineFields;

    _built pushBack [_lineKey, _lineTitle, _lineLabel, _builtFields, _lineIndex];
} forEach _lines;

// EVERY ROOT REPORT ENDS WITH REMARKS (the report-forms handoff), before the
// ROUTING line where one exists. The deck is data the mod does not own, so a
// card without one is said in the RPT rather than refused or patched here.
if ((_template get "kind") in ["root", "both"]) then {
    private _tail = _built select [(count _built - 2) max 0];
    if ((_tail findIf {"REMARKS" in toUpper ((_x # 1) + " " + (_x # 2))}) < 0) then {
        INFO_1("template '%1' has no REMARKS line at its end",_id);
    };
};

_template set ["lines", _built];
_template set ["fields", _fields];
_template set ["order", _order];

GVAR(templates) set [_id, _template];
GVAR(templateIds) pushBack _id;

_id
