#include "script_component.hpp"
/*
 * Author: YonV
 * Renders a message as plain text, line by line, the way it would be read out
 * over the net. There is no UI yet, so this is how a message is seen at all -
 * in a notification, in a systemChat line, in the debug console. When a UI does
 * arrive it renders from the same payload, not from this string.
 *
 * Empty fields are skipped. A form with eleven lines of which two are filled is
 * a two line report, not nine blank rows.
 *
 * Arguments:
 * 0: Template id <STRING>
 * 1: Payload <ARRAY> - [fieldKey, value] pairs
 * 2: Include the template's own title as a first line <BOOL> (optional, default true)
 *
 * Return Value:
 * Rendered report <STRING>
 *
 * Example:
 * private _text = ["sitrep", _payload] call jmfsb_messaging_fnc_render
 *
 * Public: Yes
 */

params [["_templateId", "", [""]], ["_payload", [], [[]]], ["_withTitle", true, [false]]];

private _template = [_templateId] call FUNC(template);
if (_template isEqualTo createHashMap) exitWith {""};

private _values = createHashMapFromArray _payload;
private _out = [];

if (_withTitle) then {
    _out pushBack (_template get "title");
};

// A FRAGO (2026-11-09) reads as the order it changes, only the changed lines,
// old value and new (FUNC(fragoLines)), then its reason.
if (_templateId isEqualTo FRAGO_ID) exitWith {
    private _card = [_values getOrDefault [FRAGO_CARD_KEY, ""]] call FUNC(template);
    if (_card isNotEqualTo createHashMap) then {
        _out pushBack format ["%1 - %2", toUpper (_card get "title"), "CHANGES"];
        _out pushBack "";
    };
    {
        _x params ["_lineTitle", "_lineLabel", "_change"];
        _out pushBack format ["%1 - %2", toUpper _lineTitle, _lineLabel];
        _out pushBack _change;
        _out pushBack "";
    } forEach ([_payload] call FUNC(fragoLines));
    private _reason = _values getOrDefault [FRAGO_REASON_KEY, ""];
    if (_reason isEqualType "" && {trim _reason isNotEqualTo ""}) then {
        _out pushBack "REASON";
        _out pushBack (trim _reason);
    };
    _out joinString endl
};

// THE CARD'S OWN SHAPE, not a flattened paragraph - the user's spec, in red:
// every filled line renders as its key and title ("M - MECHANISM OF INJURY &
// TIME"), the answer on the next line, and a blank line after, for every
// template. A report should read back the way the card was filled in.
{
    _x params ["_lineKey", "_lineTitle", "_lineLabel", "_fields"];

    private _parts = [];

    {
        private _key = _x get "key";
        private _value = _values getOrDefault [_key, ""];
        private _prefix = _x get "prefix";

        // FUNC(fieldText) - a tick as its prefix, a grid with its marker's
        // name, the rest as typed (split out 2026-11-09 for the FRAGO).
        private _text = [_x, _value, _values] call FUNC(fieldText);

        if (_text != "") then {
            // A prefix is the label the card prints in front of the value -
            // "URGENT 2", "EKIA 4" - so it is joined to the value, not listed
            // beside it. A bool has already folded its prefix into the text.
            if (_prefix != "" && {_x get "type" != "bool"}) then {
                _text = format ["%1%2", _prefix, _text];
            };
            _parts pushBack _text;
        };
    } forEach _fields;

    if (_parts isNotEqualTo []) then {
        _out pushBack format ["%1 - %2", toUpper _lineTitle, _lineLabel];
        _out pushBack (_parts joinString ", ");
        _out pushBack "";
    };
} forEach (_template get "lines");

_out joinString endl
