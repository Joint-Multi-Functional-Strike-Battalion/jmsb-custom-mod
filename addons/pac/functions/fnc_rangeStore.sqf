#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_rangeStore

Description:
    Server: keeps one finished shooting-range run on the shooter's record -
    [date, range, mode, detail, hits, shown, seconds] onto "ranges". The
    last PAC_RANGE_KEEP runs of each range are kept; the oldest of that
    range goes. Sent by jmfsb_range when a run finishes on a range set to
    save to PAC.

    THE SENDER MUST BE THE SHOOTER, as for a loadout (FUNC(loadoutStore)):
    a player keeps their own score and nobody else's.

    It reaches the database with the record's next database save (log on,
    log off, an admin SAVE or the mission's end), as every record change
    does.

Parameters:
    0: The shooter <OBJECT>
    1: Range name <STRING>
    2: Mode <STRING>
    3: Detail - the run's settings in words <STRING>
    4: Hits <NUMBER>
    5: Targets shown <NUMBER>
    6: Seconds <NUMBER>

Returns:
    Kept <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

params [
    ["_unit", objNull, [objNull]],
    ["_range", "", [""]],
    ["_mode", "", [""]],
    ["_detail", "", [""]],
    ["_hits", 0, [0]],
    ["_shown", 0, [0]],
    ["_seconds", 0, [0]]
];

if (!isServer || {isNull _unit} || _range isEqualTo "") exitWith {false};
if (remoteExecutedOwner isNotEqualTo (owner _unit) && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    WARNING_2("rangeStore refused: owner %1 sent a score for %2",remoteExecutedOwner,name _unit);
    false
};
if (GVAR(readOnly)) exitWith {false};

private _uid = [_unit] call FUNC(uid);
private _rec = [_uid, name _unit] call FUNC(record);
private _now = [] call FUNC(stamp);

private _runs = _rec getOrDefault ["ranges", []];
if !(_runs isEqualType []) then {_runs = []};
_runs pushBack [_now, _range, _mode, _detail, _hits max 0, _shown max 0, _seconds max 0];

// Oldest first, so the first of a range over the cap is its oldest.
private _ofRange = _runs select {(_x param [1, ""]) isEqualTo _range};
if (count _ofRange > PAC_RANGE_KEEP) then {
    private _drop = _ofRange select [0, count _ofRange - PAC_RANGE_KEEP];
    _runs = _runs - _drop;
};

_rec set ["ranges", _runs];
_rec set ["updatedAt", _now];
GVAR(players) set [_uid, _rec];

[] call FUNC(storeSave);

["TAC//PAC", format ["%1: score kept on your record.", _range], [0.4, 0.702, 0.4, 1]] remoteExec ["jmfsb_notify_fnc_notify", owner _unit];

true
