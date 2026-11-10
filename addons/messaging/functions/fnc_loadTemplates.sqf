#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the mission's report deck out of config and registers every template.
 *
 * THE DECK IS MISSION DATA NOW. It was templates.inc.sqf - 590 lines of nested
 * SQF arrays #included into this addon's preInit - so adding a line to a card,
 * or a card to the deck, meant editing and rebuilding the mod. It is
 * config\config_messaging.hpp in the mission instead, read through
 * missionConfigFile: no file paths, no preprocessing, and it works the same on
 * a dedicated server and inside a packed mission PBO.
 *
 * ORDER IS READ FROM lineOrder[], NOT FROM THE CLASS ORDER. Config class order
 * survives rapify, but nothing in the language promises it and a line deck read
 * in the wrong order is a card nobody can fill in. Each template names its lines
 * explicitly, so the order is stated rather than inferred.
 *
 * IT IS lineOrder[], NOT lines[], AND THAT IS NOT A STYLE CHOICE. Config names
 * are CASE-INSENSITIVE: an array called lines[] and a class called Lines are one
 * identifier. The parser reports "Member already defined", the array wins, and
 * every line lookup then fails with "'lines/' is not a class" - which is exactly
 * what happened, for all 94 lines of the deck, in one build.
 *
 * The field-key contract is unchanged and still lives in FUNC(registerTemplate):
 * a line's `name` is what field keys are built from, so "Line 1" gives Line1.A
 * and a SALUTE's "S" gives S.A. Renaming a line renames a field.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * How many templates were registered <NUMBER>
 *
 * Example:
 * call jmfsb_messaging_fnc_loadTemplates
 *
 * Public: No
 */

private _root = missionConfigFile >> "JMFSBFR_Templates";

if !(isClass _root) exitWith {
    // LOUD, because a mission with no deck has no reports at all. Every other
    // mission in this collection still needs its own copy of the file.
    // With TAC//PAC loaded the deck usually arrives with its structure (the
    // database's), after this - not a warning then, a note.
    if (isClass (configFile >> "CfgPatches" >> "jmfsb_pac")) then {
        INFO("no JMFSBFR_Templates class in the mission config - the report deck comes with TAC//PAC's structure, if the unit keeps one");
    } else {
        WARNING("no JMFSBFR_Templates class in the mission config - this mission has no report deck");
    };
    0
};

private _made = 0;

{
    private _tCfg = _x;
    private _id = configName _tCfg;

    private _options = [];

    // Template options. Only what the mission actually set is passed on;
    // FUNC(registerTemplate) owns every default.
    {
        if (isText (_tCfg >> _x)) then {_options pushBack [_x, getText (_tCfg >> _x)]};
    } forEach ["kind", "priority", "subject", "transitionsTo", "senderMustBe", "reportable", "broadcast", "routing", "anchor"];

    {
        if (isArray (_tCfg >> _x)) then {_options pushBack [_x, getArray (_tCfg >> _x)]};
    } forEach ["replyableWith", "allowedFrom"];

    // dangerClose = 600; - metres (user, 2026-11-01, D8).
    {
        if (isNumber (_tCfg >> _x)) then {_options pushBack [_x, getNumber (_tCfg >> _x)]};
    } forEach ["dangerClose"];

    private _lines = [];

    {
        private _lCfg = _tCfg >> "Lines" >> _x;

        if !(isClass _lCfg) then {
            WARNING_2("template '%1' names a line '%2' that has no class - skipped",_id,_x);
            continue;
        };

        private _fields = [];

        {
            private _fCfg = _x;
            private _fieldOpts = [];

            // BOOLEANS ARRIVE AS NUMBERS. A config has no boolean type, so the
            // mission writes 1 or 0 and they are turned back here - the engine
            // downstream tests them with `if`, which a number would satisfy for
            // the wrong reason.
            {
                if (isNumber (_fCfg >> _x)) then {_fieldOpts pushBack [_x, getNumber (_fCfg >> _x) > 0]};
            } forEach ["required", "noCur"];

            {
                if (isNumber (_fCfg >> _x)) then {_fieldOpts pushBack [_x, getNumber (_fCfg >> _x)]};
            } forEach ["min", "max"];

            {
                if (isText (_fCfg >> _x)) then {_fieldOpts pushBack [_x, getText (_fCfg >> _x)]};
            } forEach ["exclusive", "autoFill", "source"];

            if (isArray (_fCfg >> "choices")) then {
                _fieldOpts pushBack ["choices", getArray (_fCfg >> "choices")];
            };

            _fields pushBack [
                getText (_fCfg >> "prefix"),
                getText (_fCfg >> "hint"),
                getText (_fCfg >> "type"),
                _fieldOpts
            ];
        } forEach (configProperties [_lCfg >> "Fields", "isClass _x", false]);

        _lines pushBack [getText (_lCfg >> "name"), getText (_lCfg >> "label"), _fields];
    } forEach (getArray (_tCfg >> "lineOrder"));

    if (([_id, getText (_tCfg >> "title"), getText (_tCfg >> "short"), _lines, _options] call FUNC(registerTemplate)) isNotEqualTo "") then {
        _made = _made + 1;
    };
} forEach (configProperties [_root, "isClass _x", false]);

INFO_1("%1 report templates loaded from the mission config.",_made);

_made
