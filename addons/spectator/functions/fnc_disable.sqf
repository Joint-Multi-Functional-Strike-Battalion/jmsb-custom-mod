#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function disables spectator functionality.
 *
 * Server only: every machine gets FUNC(stop) by remoteExec, which takes it
 * only from the server (review R1: it was a CBA event any client could raise
 * to throw every player out of spectator).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: New spectator state <BOOL>
 *
 * Example:
 * [0] call jmfsb_spectator_fnc_disable
 *
 * Public: No
 */

if (!isServer) exitWith {false};

[] remoteExecCall [QFUNC(stop), 0];

false
