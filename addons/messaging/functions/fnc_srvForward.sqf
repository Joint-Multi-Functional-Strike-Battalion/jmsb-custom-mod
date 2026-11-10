#include "script_component.hpp"
/*
 * Author: YonV
 * Forwards a reportable message to ALiVE's C2ISTAR - a CONTACTREP as a spotrep,
 * a SITREP as a sitrep, each with a companion map marker. Carried over from
 * ctab_groups, which did the same job by naming ALiVE symbols directly.
 *
 * IT DOES NOT NAME ONE HERE. Exactly one addon in this mod may know ALiVE
 * exists and it is adapter_alive; that is rule 4 of docs/new.md and
 * tools/check_invariants.py fails the build over it. So this function's whole
 * job is to turn a template payload into the flat field list the adapter takes,
 * and to know nothing else.
 *
 * The field mapping is by LINE TITLE - S/A/L/U/T/E/R on a CONTACTREP, and
 * Callsign/Location/Enemy/Friendly/Civ/Status/Remarks on a SITREP. Rename a
 * line title in templates.inc.sqf and this stops finding its fields.
 *
 * Arguments:
 * 0: Sending player <OBJECT>
 * 1: Template <HASHMAP>
 * 2: Payload <ARRAY>
 * 3: Thread <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_template", createHashMap, [createHashMap]],
    ["_payload", [], [[]]],
    ["_thread", createHashMap, [createHashMap]]
];

if (!isServer || {!GVAR(aliveReports)} || {isNull _unit}) exitWith {};

private _kind = _template get "reportable";
if !(_kind in ["spotrep", "sitrep"]) exitWith {};

// Without ALiVE there is no C2ISTAR to file with. Said once, not once a report
// (user, 2026-11-02); the message itself went out as normal.
if (isNil QEFUNC(adapter_alive,postReport)) exitWith {
    ["Report forwarding", "reportable cards are not posted anywhere"] call EFUNC(common,aliveLoaded);
};

private _values = createHashMapFromArray _payload;

// [line key, field letter, fallback] -> a string the adapter can hand on. The
// value is stripped of the quote characters that would break a config string
// on the far side.
private _fnc_val = {
    params ["_line", ["_letter", "A"], ["_fallback", ""]];
    private _raw = _values getOrDefault [format ["%1.%2", _line, _letter], ""];

    private _text = switch (true) do {
        case (_raw isEqualType ""): {trim _raw};
        case (_raw isEqualType 0): {str _raw};
        case (_raw isEqualType false): {["", "yes"] select _raw};
        case (_raw isEqualType [] && {count _raw >= 2}): {
            // A marker's name beside its grid (user, 2026-11-05).
            private _marker = _values getOrDefault [format ["%1.%2%3", _line, _letter, MARKER_NAME_SUFFIX], ""];
            private _grid = mapGridPosition _raw;
            if (_marker isEqualType "" && _marker != "") then {_grid = format ["%1 (%2)", _grid, _marker]};
            _grid
        };
        default {""};
    };

    {_text = [_text, _x, ""] call CBA_fnc_replace} forEach ["""", "'", "\"];
    [_text, _fallback] select (_text == "")
};

private _pos = _thread getOrDefault ["anchorPos", getPosATL _unit];
private _grid = mapGridPosition _pos;

private _fields = if (_kind == "spotrep") then {
    [
        ["loc", ["L", "A", _grid] call _fnc_val],
        ["size", ["S", "A", "Unknown"] call _fnc_val],
        ["type", ["U", "A", "Unknown"] call _fnc_val],
        ["activity", toUpper (["A", "A", "STATIC"] call _fnc_val)],
        ["remarks", ([["E", "A", ""] call _fnc_val, ["R", "A", ""] call _fnc_val] select {_x != ""}) joinString " | "],
        ["dateTime", ["T", "A", "NOW"] call _fnc_val]
    ]
} else {
    [
        // The SITREP's CALL SIGN line is gone from the deck (report-card
        // review, 2026-11-02, D10: the sender is on every message): the
        // sender's group id, unless an older deck still carries the line.
        ["callsign", ["Callsign", "A", groupId (group _unit)] call _fnc_val],
        ["loc", ["Location", "A", _grid] call _fnc_val],
        ["en", ["Enemy", "A", "NONE"] call _fnc_val],
        ["ekia", ["Enemy", "B", "0"] call _fnc_val],
        ["ff", ["Friendly", "A", ""] call _fnc_val],
        ["fkia", ["Friendly", "B", "0"] call _fnc_val],
        ["fwia", ["Friendly", "C", "0"] call _fnc_val],
        ["civ", ["Civ", "A", "NONE"] call _fnc_val],
        ["ammo", ["Status", "A", "GREEN"] call _fnc_val],
        ["cas", ["Status", "B", "GREEN"] call _fnc_val],
        ["veh", ["Status", "C", "GREEN"] call _fnc_val],
        ["cs", ["Status", "D", "GREEN"] call _fnc_val],
        ["remarks", ["Remarks", "A", ""] call _fnc_val],
        ["markerType", GVAR(sitrepMarkerType)]
    ]
};

[_kind, _unit, _pos, _fields, GVAR(aliveLocality)] call EFUNC(adapter_alive,postReport);
