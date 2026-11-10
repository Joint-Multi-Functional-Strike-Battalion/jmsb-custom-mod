#include "script_component.hpp"
/*
 * Author: YonV
 * Files one sighting on a side's threat board - what that side KNOWS, as
 * opposed to what is true.
 *
 * THE BOARD IS THE POINT OF THE WHOLE DESIGN. JMSB's sensors used to be wired
 * straight to their own shooters: the counter-battery radar fired the
 * counter-battery guns, base defense's recon fed base defense's mortars, the
 * EW net dispatched the EW response. Three sensors, three shooters, three
 * private wires, and nothing else in the mod could ever hear any of them. The
 * board makes a sighting a fact ANY consumer can act on, so N sensors and M
 * shooters cost N+M wires rather than N*M.
 *
 * A contact is a BELIEF and carries its own doubt:
 *   the position is where the sensor thinks it is, error is how wrong that
 *   might be, and confidence falls off with age until the contact is dropped.
 * Consumers that shoot use the belief; consumers that search use the error.
 *
 * Merging is by proximity, not identity: two sensors reporting the same fight
 * from different angles is ONE contact that got better, not two contacts. The
 * merged contact takes the tighter error - a second bearing is exactly what
 * narrows a fix - and the newest timestamp.
 *
 * Arguments:
 * 0: Owning side - whose board this is <SIDE>. sideUnknown means the sensor has
 *    no side of its own (a counter-battery radar serving a coalition): the
 *    sighting is filed on the board of EVERY side hostile to the target.
 * 1: Target side - who was seen <SIDE>
 * 2: Believed position, AGL <ARRAY> - the frame is AGL because every consumer
 *    is ground-referenced: fire missions and spawns all take
 *    world positions. Sensors working in ASL convert before posting.
 * 3: Position error, m - 0 for an exact sighting <NUMBER>
 * 4: Source tag, for consumers that care how it was seen <STRING>
 *    ("ew", "cb", "recon", "radar", "visual")
 * 5: Object, when the sensor saw a specific one <OBJECT> (optional)
 *
 * Return Value:
 * The contact id, "" if refused <STRING>
 *
 * Example:
 * [east, west, _pos, 150, "ew"] call jmfsb_common_fnc_contactReport
 */

if (!isServer) exitWith {""};

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_target", sideUnknown, [sideUnknown]],
    ["_pos", [], [[]]],
    ["_error", 0, [0]],
    ["_source", "", [""]],
    ["_object", objNull, [objNull]]
];

if (_pos isEqualTo [] || {_target isEqualTo sideUnknown}) exitWith {""};

// A sideless sensor files with everyone who would care. The counter-battery
// radar is the case: it has no side in its config, and a picket serving a
// coalition tells the whole coalition. Recursion is one level deep - each
// call below names a real side.
if (_side isEqualTo sideUnknown) exitWith {
    private _ids = [];
    {
        if ((_x getFriend _target) < 0.6) then {
            private _id = [_x, _target, _pos, _error, _source, _object] call FUNC(contactReport);
            if (_id != "") then {_ids pushBack _id};
        };
    } forEach [east, west, independent];
    [_ids select 0, ""] select (_ids isEqualTo [])
};

private _board = GVAR(boards) getOrDefault [str _side, []];
private _now = CBA_missionTime;
_pos = +_pos;
if (count _pos < 3) then {_pos pushBack 0};

// Same fight, seen again? Merge rather than stack. The window is the larger
// of the two errors: a 400 m fix and a 50 m fix 300 m apart are the same
// target as far as the loose one can tell.
private _idx = _board findIf {
    _x params ["", "", "_ctarget", "_cpos", "_cerror"];
    _ctarget isEqualTo _target && {(_cpos distance2D _pos) < ((_error max _cerror) max CONTACT_MERGE_MIN)}
};

if (_idx > -1) then {
    (_board select _idx) params ["_id", "", "", "_cpos", "_cerror", "", "", "_sources"];

    // the better fix wins the position; a worse one still refreshes the age
    if (_error < _cerror) then {
        (_board select _idx) set [3, _pos];
        (_board select _idx) set [4, _error];
    };
    (_board select _idx) set [5, _now];
    _sources pushBackUnique _source;
    if (!isNull _object) then {(_board select _idx) set [8, _object]};

    GVAR(boards) set [str _side, _board];
    _id
} else {
    GVAR(contactSeq) = GVAR(contactSeq) + 1;
    private _id = format ["C%1", GVAR(contactSeq)];

    // [id, side, target, pos, error, seen, first seen, sources, object]
    _board pushBack [_id, _side, _target, _pos, _error, _now, _now, [_source], _object];
    GVAR(boards) set [str _side, _board];

    if (GVAR(boardDebug)) then {
        diag_log text format ["[jmfsb_common] contact %1: %2 sees %3 at %4 +/-%5 m (%6)",
            _id, _side, _target, mapGridPosition _pos, round _error, _source];
    };

    _id
};
