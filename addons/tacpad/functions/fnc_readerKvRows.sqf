#include "script_component.hpp"
/*
 * Author: YonV
 * A filed card's lines as the rows of one key/value column (FUNC(readerKv)):
 * [label, value, critical] per filled line, off the template's own line
 * definitions - so a card added to the deck reads here for free.
 *
 * EMPTY LINES ARE LEFT OUT (user, 2026-11-02: "the 2 column view in the
 * message history is hard to read"). An optional line nobody filled is not a
 * row with a dash in it. A ticked box reads as its own word - the label
 * SECURITY, the value RED - and a grid at the player's own digit count
 * (jmfsb_devices_fnc_overlayGrid), the engine's square without devices.
 *
 * Arguments:
 * 0: The message <HASHMAP>
 * 1: Number each line whose label carries no number of its own <BOOL> (optional, default false)
 *
 * Return Value:
 * Rows [[label, value, critical], ...] - critical is a filled grid; [] when no line is filled <ARRAY>
 *
 * Example:
 * private _rows = [_rootMsg, true] call jmfsb_tacpad_fnc_readerKvRows
 *
 * Public: No
 */

params [["_msg", createHashMap, [createHashMap]], ["_numbered", false, [false]]];

// A FRAGO (2026-11-09) reads as the order it changes: only the changed lines,
// old value -> new (EFUNC(messaging,fragoLines)), then its reason.
if ((_msg getOrDefault ["templateId", ""]) isEqualTo FRAGO_ID && !isNil QEFUNC(messaging,fragoLines)) exitWith {
    private _fragoPayload = _msg getOrDefault ["payload", []];
    private _fragoRows = ([_fragoPayload] call EFUNC(messaging,fragoLines)) apply {
        _x params ["_lineTitle", "_lineLabel", "_change"];
        private _label = toUpper trim _lineLabel;
        if (_label isEqualTo "") then {_label = toUpper trim _lineTitle};
        [_label, _change, false]
    };
    private _reason = (createHashMapFromArray _fragoPayload) getOrDefault [FRAGO_REASON_KEY, ""];
    if (_reason isEqualType "" && {trim _reason isNotEqualTo ""}) then {_fragoRows pushBack [FRAGO_REASON_LABEL, trim _reason, false]};
    _fragoRows
};

private _template = [_msg getOrDefault ["templateId", ""]] call EFUNC(messaging,template);
private _lines = _template getOrDefault ["lines", []];
if (_lines isEqualTo []) exitWith {[]};

private _payload = createHashMapFromArray (_msg getOrDefault ["payload", []]);
private _rows = [];

{
    _x params ["", ["_lineTitle", ""], ["_lineLabel", ""], ["_fields", []]];

    private _parts = [];
    private _critical = false;
    {
        private _type = _x getOrDefault ["type", ""];
        private _prefix = trim (_x getOrDefault ["prefix", ""]);
        private _v = _payload getOrDefault [_x getOrDefault ["key", ""], ""];

        private _text = switch (_type) do {
            // A bool slot can hold a STRING (reply prefills, edit harvests); a
            // truthy one counts as ticked, as jmfsb_messaging_fnc_render reads it.
            case "bool": {
                private _on = _v isEqualTo true;
                if (_v isEqualType "") then {_on = (toLower _v) in READER_KV_TICKED};
                ["", [_prefix, READER_KV_YES] select (_prefix isEqualTo "")] select _on
            };
            // A position is drawn as a grid; a grid typed by hand is a string.
            case "grid": {
                private _grid = "";
                if (_v isEqualType "") then {_grid = trim _v};
                if (_v isEqualType []) then {
                    if (count _v >= 2) then {
                        _grid = if (isNil QEFUNC(devices,overlayGrid)) then {mapGridPosition _v} else {([_v] call EFUNC(devices,overlayGrid)) select 0};
                    };
                };
                // Picked from a map marker: its name beside the grid (user,
                // 2026-11-05), from the payload's sibling key.
                private _marker = _payload getOrDefault [(_x getOrDefault ["key", ""]) + MARKER_NAME_SUFFIX, ""];
                if (_grid isNotEqualTo "" && _marker isEqualType "" && _marker isNotEqualTo "") then {
                    _grid = format ["%1 (%2)", _grid, _marker];
                };
                _grid
            };
            default {
                private _said = "";
                if (_v isEqualType "") then {_said = trim _v};
                if (_v isEqualType 0) then {_said = str _v};
                _said
            };
        };
        if (_text isEqualTo "") then {continue};

        if (_type isEqualTo "grid") then {_critical = true};
        // The prefix is the card's own word in front of the answer - "A URGENT 2";
        // a bool has already read as its prefix.
        if (_type isNotEqualTo "bool" && _prefix isNotEqualTo "") then {
            _text = format ["%1 %2", _prefix, _text];
        };
        _parts pushBack _text;
    } forEach _fields;

    if (_parts isEqualTo []) then {continue};

    private _label = toUpper trim _lineLabel;
    if (_label isEqualTo "") then {_label = toUpper trim _lineTitle};
    if (_numbered) then {
        private _own = ((_label select [0, 1]) in READER_KV_DIGITS) || (((_label splitString " ") param [0, ""]) isEqualTo READER_KV_LINE_WORD);
        if (!_own) then {_label = format ["%1. %2", _forEachIndex + 1, _label]};
    };

    _rows pushBack [_label, _parts joinString READER_KV_JOIN, _critical];
} forEach _lines;

_rows
