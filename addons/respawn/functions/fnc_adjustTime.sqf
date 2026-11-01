#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function raises adjustTimeLocal event on all clients.
 *
 * Arguments:
 * 0: New respawn time delay <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [30] call jmfsb_respawn_fnc_adjustTime
 *
 * Public: No
 */

params ["_newTime"];

if (!isServer) exitWith {};

// To every player by remoteExec, taken only from the server (review S7).
[_newTime] remoteExecCall [QFUNC(adjustTimeLocal), 0];

nil
