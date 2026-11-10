#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function disables respawn for local player. Sent by the server
 * (FUNC(toggle)) by remoteExec and taken only from it (review S7: it was a
 * CBA event any client could raise for everyone).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_respawn_fnc_disable", 0]
 *
 * Public: No
 */

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

// Save current elapsed time for possible further respawn restart
GVAR(timeElapsed) = GVAR(time) - playerRespawnTime;

setPlayerRespawnTime TIME_DISABLED;

nil
