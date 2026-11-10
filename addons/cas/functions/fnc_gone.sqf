#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a module's drone is LOST - shot down. THE RESPAWN COUNT (user,
 * 2026-11-02: "make sure there is a respawn count for each support, default no
 * respawns"; "all support aircraft needs to be virtual till tasked"): with a
 * respawn left one is spent and the asset is REARMING ("replacing") for the
 * module's Respawn Delay - the next tasking after it makes a new drone; with
 * none left the asset is gone - off the support list, and a card to it answers
 * UNABLE - NO AIRFRAME. A drone that flies home and is removed (FUNC(recover))
 * uses none.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Why, for the RPT <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "shot down"] call jmfsb_cas_fnc_gone
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_why", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
private _running = !((_logic getVariable [QGVAR(status), STATUS_IDLE]) in STATUSES_NO_RUN);

private _left = _logic getVariable [QGVAR(respawnsLeft), MODULE_RESPAWNS];
if (_left <= 0) exitWith {
    _logic setVariable [QGVAR(gone), true, true];
    if (!_running) then {_logic setVariable [QGVAR(status), STATUS_EXPENDED, true]};
    WARNING_2("%1 drone %2 - no respawns left, the asset is gone",_callsign,_why);
};

private _delay = _logic getVariable [QGVAR(respawnDelay), MODULE_RESPAWN_DELAY];
_logic setVariable [QGVAR(respawnsLeft), _left - 1, true];
_logic setVariable [QGVAR(respawnAt), CBA_missionTime + _delay, true];
if (!_running) then {_logic setVariable [QGVAR(status), STATUS_REPLACING, true]};
INFO_4("%1 drone %2 - a replacement in %3 s, %4 respawns left after it",_callsign,_why,round _delay,_left - 1);
