#include "script_component.hpp"
/*
 * Author: YonV
 * How many patrols a side actually has up, pruning the entries that have died
 * since the last look.
 *
 * A patrol is one of two things and the list holds both. A profile ID is a
 * STRING and ALiVE owns its lifetime. An OBJECT is a drone ALiVE refused to
 * profile - it blacklists UAV crew and airframes on purpose - so jmfsb flies
 * that one live and has to notice when it is shot down.
 *
 * Without this the ceiling counted destroyed airframes forever and the side
 * quietly stopped replacing anything.
 *
 * Arguments:
 * 0: The side <SIDE>
 *
 * Return Value:
 * Patrols still up <NUMBER>
 *
 * Example:
 * [east] call jmfsb_uas_fnc_livePatrols
 */

params [["_side", sideUnknown, [sideUnknown]]];

private _key = str _side;
private _list = GVAR(patrols) getOrDefault [_key, []];
if (_list isEqualTo []) exitWith {0};

// OBJECTS ONLY. Patrols were once tracked either as live objects or as
// ALiVE profile ids; there are no profiled patrols any more - an aircraft
// cannot be profiled, and asking was what deleted them. A string left in
// the ledger by an older session is dropped rather than pruned against a
// profile system that never held it.
private _kept = _list select {!isNull _x && {alive _x}};

if (count _kept != count _list) then {
    GVAR(patrols) set [_key, _kept];
};

count _kept
