#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function restarts all spectators.
 *
 * Server only: every machine gets FUNC(reloadLocal) by remoteExec, which takes
 * it only from the server (review R1: it was a CBA event any client could
 * raise).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call jmfsb_spectator_fnc_restart
 *
 * Public: No
 */

if (!isServer || {time < 1}) exitWith {};

WARNING("Restarting spectator!");
[] remoteExecCall [QFUNC(reloadLocal), 0];

nil
