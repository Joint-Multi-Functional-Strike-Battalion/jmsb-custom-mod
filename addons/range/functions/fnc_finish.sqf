#include "..\script_component.hpp"
/*
 * Author: YonV
 * Ends the run on the shooter's machine: stands the targets back up, frees
 * the range and, for a finished run, tells the shooter and everyone near
 * them the score - and keeps it on the shooter's PAC record when the range
 * says so (jmfsb_pac_fnc_rangeStore, on the server).
 *
 * Arguments:
 * 0: Finished - false when it was stopped <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_done", false, [false]]];

private _s = GVAR(session);
GVAR(session) = createHashMap;
if (count _s isEqualTo 0) exitWith {};

private _range = _s get "range";
private _cfg = _range getVariable [QGVAR(cfg), createHashMap];
private _targets = _s get "targets";
private _name = _cfg getOrDefault ["name", ""];

{
    _x setVariable [QGVAR(hit), nil];
    [_x, TARGET_UP] call FUNC(setTarget);
} forEach _targets;

if (((_range getVariable [QGVAR(run), []]) param [0, objNull]) isEqualTo player) then {
    _range setVariable [QGVAR(run), [], true];
};

if (!_done) exitWith {
    [player, format ["%1: stopped - no score.", _name], NOTE_BAD] call FUNC(tell);
};

private _mode = _s get "mode";
private _hits = _s get "hits";
private _total = _s get "shown";
private _seconds = if (_mode isEqualTo MODE_TIMED) then {
    _s get "duration"
} else {
    (round ((CBA_missionTime - (_s get "startAt")) * 10)) / 10
};
private _pct = if (_total > 0) then {round (100 * _hits / _total)} else {0};
private _modeName = MODE_NAMES select _mode;
private _detail = [_mode, _s get "duration", _s get "count", _s get "exposure", count _targets] call FUNC(detail);

private _source = (_cfg getOrDefault ["controllers", [player]]) param [0, player];
[QGVAR(say), [_source, SOUND_FINISH]] call CBA_fnc_globalEvent;

[player, format ["%1 - %2: %3 of %4 hits (%5%%) in %6 s.", _name, name player, _hits, _total, _pct, _seconds], NOTE_GOOD] call FUNC(tell);
INFO_6("%1 | %2 | %3 | %4/%5 in %6 s",_name,name player,_modeName,_hits,_total,_seconds);

if (_cfg getOrDefault ["savePac", false] && {!isNil QEFUNC(pac,rangeStore)}) then {
    [player, _name, _modeName, _detail, _hits, _total, _seconds] remoteExecCall [QEFUNC(pac,rangeStore), 2];
};
