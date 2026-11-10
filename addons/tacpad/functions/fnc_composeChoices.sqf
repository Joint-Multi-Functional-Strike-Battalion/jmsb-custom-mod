#include "script_component.hpp"
/*
 * Author: YonV
 * The picks of a choice the composer fills at runtime (user, 2026-11-02: "we
 * have pre made crates so the requested items should be a drop down of
 * them"). A field's choicesFrom names a source (CHOICE_SOURCES); the source is
 * asked with the TO line's addressees, so RESUPPLY's items are the catalog of
 * the logistics asset on TO - or of every logistics asset of the side when
 * none is there (jmfsb_support_logistics_fnc_catalogNames).
 *
 * A source whose addon is not loaded, or that answers nothing, gives no picks:
 * the field is then a typed box, as before.
 *
 * Arguments:
 * 0: The field <HASHMAP>
 *
 * Return Value:
 * The picks, strings; [] for none <ARRAY>
 *
 * Example:
 * [_field] call jmfsb_tacpad_fnc_composeChoices
 *
 * Public: No
 */

params [["_field", createHashMap, [createHashMap]]];

private _source = _field getOrDefault ["choicesFrom", ""];
if !(_source isEqualType "") exitWith {[]};
if (_source isEqualTo "") exitWith {[]};

private _at = CHOICE_SOURCES findIf {(_x select 0) isEqualTo _source};
if (_at < 0) exitWith {[]};

private _fnc = missionNamespace getVariable [(CHOICE_SOURCES select _at) select 1, {}];
if !(_fnc isEqualType {}) exitWith {[]};

private _to = ((GVAR(composeTo) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
private _picks = [_to] call _fnc;
if (isNil "_picks") exitWith {[]};
if !(_picks isEqualType []) exitWith {[]};

_picks select {_x isEqualType "" && _x isNotEqualTo ""}
