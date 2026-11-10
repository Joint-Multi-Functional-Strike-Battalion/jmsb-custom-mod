#include "script_component.hpp"
/*
 * Author: YonV
 * Reads a side's threat board - the public way, and the only way.
 *
 * Same discipline the EW zone registry set: consumers never touch the store,
 * so the shape can change without hunting every reader in the mod. What comes
 * back is a COPY, so a consumer that sorts or trims its results cannot corrupt
 * anybody else's picture.
 *
 * CONFIDENCE, not just age: a contact decays from 1 at the moment it was seen
 * to 0 at CONTACT_LIFETIME, and consumers filter on it. A shooter wants high
 * confidence and a tight error; a patrol worth sending to look is happy with
 * either being poor. Expired contacts are dropped here rather than by a
 * sweeper - the board is only ever wrong when somebody is reading it, so this
 * is the honest place to tidy.
 *
 * Arguments:
 * 0: Owning side <SIDE>
 * 1: Least confidence, 0-1 <NUMBER> (optional, default 0 - everything live)
 * 2: Greatest position error, m - 0 for no limit <NUMBER> (optional)
 * 3: Source filter <ARRAY of STRING> (optional, [] for any)
 *
 * Return Value:
 * Contacts, best confidence first. Each:
 * [id, targetSide, pos, error, confidence, age s, sources, object] <ARRAY>
 *
 * Example:
 * [east, 0.5, 300] call jmfsb_common_fnc_contactGet
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_minConf", 0, [0]],
    ["_maxError", 0, [0]],
    ["_sources", [], [[]]]
];

if (_side isEqualTo sideUnknown) exitWith {[]};

private _board = GVAR(boards) getOrDefault [str _side, []];
if (_board isEqualTo []) exitWith {[]};

private _now = CBA_missionTime;
private _keep = [];
private _out = [];

{
    _x params ["_id", "", "_target", "_pos", "_error", "_seen", "", "_srcs", "_object"];

    private _age = _now - _seen;
    if (_age >= CONTACT_LIFETIME) then {continue};   // expired: not kept, not returned
    _keep pushBack _x;

    private _conf = 1 - (_age / CONTACT_LIFETIME);
    if (_conf < _minConf) then {continue};
    if (_maxError > 0 && _error > _maxError) then {continue};
    if (_sources isNotEqualTo [] && {(_srcs arrayIntersect _sources) isEqualTo []}) then {continue};

    _out pushBack [_id, _target, +_pos, _error, _conf, _age, +_srcs, _object];
} forEach _board;

// only write back when something actually expired
if (count _keep != count _board) then {
    GVAR(boards) set [str _side, _keep];
};

// best confidence first - [key, index] sort, the shape SQF can actually sort
private _order = [];
{
    _order pushBack [1 - (_x select 4), _forEachIndex];
} forEach _out;
_order sort true;

_order apply {_out select (_x select 1)}
