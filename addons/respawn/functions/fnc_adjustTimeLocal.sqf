#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function adjusts new remaining respawn time with respect to current elapsed time.
 * Sent by the server (FUNC(adjustTime)) by remoteExec and taken only from it
 * (review S7: it was a CBA event any client could raise for everyone).
 *
 * Arguments:
 * 0: New respawn time delay <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [30] remoteExecCall ["jmfsb_respawn_fnc_adjustTimeLocal", 0]
 *
 * Public: No
 */

params [["_newTime", TIME_MINIMUM, [0]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

if (playerRespawnTime isEqualTo -1) exitWith {
    GVAR(oldTime) = _newTime;
    nil
};

// Calculate current elapsed time and adjust new respawn time
private _elapsedTime = GVAR(oldTime) - playerRespawnTime;
setPlayerRespawnTime (_newTime - _elapsedTime max TIME_MINIMUM);

// Save for further adjustments
GVAR(oldTime) = _newTime;

nil
