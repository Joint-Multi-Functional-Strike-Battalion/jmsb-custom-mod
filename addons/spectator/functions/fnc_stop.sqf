#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function terminates spectator for given player
 *
 * Arguments:
 * 0: player unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_spectator_fnc_stop
 *
 * Public: No
 */

params [["_player", player]];

// STOP, not start - the copy-paste from fnc_start inverted the remote
// path's meaning: "terminate spectator for that player" STARTED it there.
// Another machine's say-so only from the server (review R1: it was a CBA
// event any client could raise to throw everyone out of spectator).
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("stop: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _player) exitWith {};
if (!(local _player)) exitWith {[_player] remoteExecCall [QFUNC(stop), _player]};
if (!hasInterface) exitWith {};

["Terminate"] call BIS_fnc_EGSpectator;
// the normal way out, not a fault: INFO, so the RPT's warnings stay faults
INFO("Stopping spectator!");

nil
