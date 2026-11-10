#include "script_component.hpp"
/*
 * Author: YonV
 * What this asset is doing, as one token - and it is the ONLY place that
 * question is answered.
 *
 * The support page asks it to colour a row, FUNC(task) asks it to refuse an
 * order, and the run asks it on the way out. Three readers of one rule, so a
 * row that says IDLE cannot be a row the tasking then refuses.
 *
 * VIRTUAL UNTIL TASKED (user, 2026-11-02): with no run up there is no drone
 * and the row reads READY ("idle") and takes a request; a replacement for a
 * lost drone on its way is "replacing" (REARMING); the last drone gone (the
 * respawn count, FUNC(gone)) is "expended" - the asset is off the list
 * (FUNC(assets)) and answers UNABLE - NO AIRFRAME.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * 0: Can be tasked right now <BOOL>
 * 1: Status token <STRING> - "idle", "on station", "replacing", "expended", "cooldown", or the run's own
 * 2: Why not, "" when it can <STRING>
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "gone", "that asset is gone"]};

private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
if (_logic getVariable [QGVAR(gone), false]) exitWith {
    [false, STATUS_EXPENDED, format ["%1 has no airframe left", _callsign]]
};

private _status = _logic getVariable [QGVAR(status), STATUS_IDLE];
if !(_status in STATUSES_NO_RUN) exitWith {
    [false, _status, "that aircraft is already on a task"]
};

private _respawnAt = _logic getVariable [QGVAR(respawnAt), 0];
if (CBA_missionTime < _respawnAt) exitWith {
    [false, STATUS_REPLACING, format ["%1 has a replacement drone in %2s", _callsign, ceil (_respawnAt - CBA_missionTime)]]
};

private _readyAt = _logic getVariable [QGVAR(readyAt), 0];
if (CBA_missionTime < _readyAt) exitWith {
    [false, STATUS_COOLDOWN, format ["%1 is rearming - %2s", _callsign, ceil (_readyAt - CBA_missionTime)]]
};

[true, [_logic] call FUNC(idleStatus), ""]
