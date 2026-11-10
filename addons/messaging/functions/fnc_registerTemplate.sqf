#include "script_component.hpp"
/*
 * Author: YonV
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
 * THE MOD'S OWN CARD ALWAYS WINS (user, 2026-11-02: card changes reach the
 * game with the mod - nobody runs a script against the database). A card
 * registered with the option ["builtin", true] - one the mod carries
 * (FUNC(builtinCards), jmfsb_support_fnc_builtinCards, PAC's OPORD and
 * METT-TC, all through FUNC(registerBuiltins)) - replaces, in its place in the
 * registry order, a card of the same id a mission's own deck registered first
 * (FUNC(loadTemplates)). A deck's card over a built-in one is refused like any
 * other id registered twice; the TAC//PAC deck never gets that far - pac
 * templatesApply skips the ids the mod carries. The mission cards the mod
 * replaced are said in one RPT line the next frame.
 *
 * Arguments:
 * 0: Template id, lowercase, no spaces <STRING>
 * 1: Title as shown to the player <STRING>
 * 2: Short title, used in subjects and notifications <STRING>
 * 3: Lines <ARRAY> - each ["line title", "LINE LABEL", [field, field, ...]]
 *      field: ["prefix", "hint", "type"] or ["prefix", "hint", "type", options]
 * 4: Options <ARRAY> - [key, value] pairs, all optional (optional, default []).
 *    2026-11-09: shortLines / shortFields (the short form), assetOnly,
 *    answerOnly, assetThread, roots (who is offered it), openFields (FRAGO)
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

private _opt = createHashMapFromArray _options;
private _builtin = (_opt getOrDefault ["builtin", false]) isEqualTo true;

// The mod's card over a mission deck's: replaced where it stands.
private _replaces = false;
if (_id in GVAR(templateIds) && _builtin) then {
    _replaces = ((GVAR(templates) getOrDefault [_id, createHashMap]) getOrDefault ["builtin", false]) isNotEqualTo true;
};
if (_id in GVAR(templateIds) && !_replaces) exitWith {
    ERROR_1("template '%1' registered twice - the second one is ignored",_id);
    ""
};

// DANGER CLOSE IS PER CARD (user, 2026-11-01, D8: "a per-card option on
// callforfire in JMSB.templates, 600 m to start"). Metres; the support board
// offers its DC tick inside it. The deck is data from a database or a website,
// so anything but a positive number reads as none rather than as a broken card.
private _dangerClose = _opt getOrDefault ["dangerClose", DANGER_CLOSE_NONE];
_dangerClose = switch (true) do {
    case (_dangerClose isEqualType 0): {_dangerClose max DANGER_CLOSE_NONE};
    case (_dangerClose isEqualType ""): {(parseNumber _dangerClose) max DANGER_CLOSE_NONE};
    default {DANGER_CLOSE_NONE};
};

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
    ["anchor", _opt getOrDefault ["anchor", ""]],
    ["dangerClose", _dangerClose],
    ["builtin", _builtin],
    // THE CLASS OF A CARD (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09) - who
    // is offered it, read by the reader (tacpad threadLegal) and the support
    // core: assetOnly - what the asset says, never in the requester's menu;
    // answerOnly - offered only when the asset asks for it; assetThread -
    // offered only in a thread an asset answers; roots - only where the
    // thread's current tasking card is one of these ids ([] any).
    ["assetOnly", (_opt getOrDefault ["assetOnly", false]) isEqualTo true],
    ["answerOnly", (_opt getOrDefault ["answerOnly", false]) isEqualTo true],
    ["assetThread", (_opt getOrDefault ["assetThread", false]) isEqualTo true],
    ["roots", (_opt getOrDefault ["roots", []]) select {_x isEqualType ""}],
    // OPEN FIELDS (FRAGO, 2026-11-09): FUNC(validate) keeps payload keys the
    // card does not have, unchecked - the changed lines of another card.
    ["openFields", (_opt getOrDefault ["openFields", false]) isEqualTo true]
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
            ["noCur", _fo getOrDefault ["noCur", false]],
            // A GRID FIELD ONLY A MAP MARKER ANSWERS (user, 2026-11-02:
            // "REQUEST ON STATION should require a map marker"): the composer
            // offers the marker list alone, and FUNC(validate) refuses a typed
            // grid - a marker's pick is a position, typing is text.
            ["markerOnly", _fo getOrDefault ["markerOnly", false]],
            // A CHOICE FILLED AT RUNTIME (user, 2026-11-02: "we have pre made
            // crates so the requested items should be a drop down of them"):
            // the composer asks the named source for the picks (tacpad
            // CHOICE_SOURCES); the card's own choices stay empty, so any
            // answer passes here and the reader matches it.
            ["choicesFrom", _fo getOrDefault ["choicesFrom", ""]]
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

// THE SHORT FORM (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): one card, two
// views, the same id and keys, so the asset reads either. shortLines names the
// lines the short form keeps, by line title or key ("Line 5" or "Line5");
// shortFields, where a kept line holds more than the short form wants, the
// only fields of it kept (CAS line 8: the DANGER CLOSE tick, not the auto
// direction). "short" on the card is the field keys the short view draws, in
// card order; [] - the card has one form. A required field is always kept:
// the short form may never hide what the card will not send without.
private _shortLines = ((_opt getOrDefault [SHORT_LINES_KEY, []]) select {_x isEqualType ""}) apply {_x regexReplace ["\s+", ""]};
private _shortFields = (_opt getOrDefault [SHORT_FIELDS_KEY, []]) select {_x isEqualType ""};
private _shortKeys = [];
if (_shortLines isNotEqualTo []) then {
    {
        private _field = _fields get _x;
        private _line = _field get "line";
        private _lineKeys = _order select {((_fields get _x) get "line") isEqualTo _line};
        private _picked = _lineKeys select {_x in _shortFields};
        private _kept = (_line in _shortLines) && {_picked isEqualTo [] || {_x in _picked}};
        if (_kept || {_field get "required"}) then {_shortKeys pushBack _x};
    } forEach _order;
};
_template set ["shortKeys", _shortKeys];

GVAR(templates) set [_id, _template];
if (!_replaces) then {
    GVAR(templateIds) pushBack _id;
};

// ONE LINE FOR EVERY MISSION CARD THE MOD REPLACED, the next frame: thirty
// cards replaced at once are one line in the RPT, not thirty.
if (_replaces) then {
    private _due = localNamespace getVariable [QGVAR(builtinReplaced), []];
    _due pushBack _id;
    localNamespace setVariable [QGVAR(builtinReplaced), _due];
    if (count _due > 1) exitWith {};
    [{
        private _replaced = localNamespace getVariable [QGVAR(builtinReplaced), []];
        localNamespace setVariable [QGVAR(builtinReplaced), []];
        private _replacedText = _replaced joinString ", ";
        INFO_2("the mod's own cards replaced %1 of the mission deck's: %2",count _replaced,_replacedText);
    }] call CBA_fnc_execNextFrame;
};

_id
