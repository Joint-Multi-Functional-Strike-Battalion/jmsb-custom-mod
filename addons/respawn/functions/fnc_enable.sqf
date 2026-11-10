#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function enables respawn for local player. Sent by the server
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
 * [] remoteExecCall ["jmfsb_respawn_fnc_enable", 0]
 *
 * Public: No
 */

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

// Restart counter where it stopped
setPlayerRespawnTime (GVAR(time) - GVAR(timeElapsed) max TIME_MINIMUM);

nil
