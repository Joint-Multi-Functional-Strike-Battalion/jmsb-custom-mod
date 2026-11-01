#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function toggles respawn enabled/disabled
 *
 * Arguments:
 * 0: Desired respawn state <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call jmfsb_respawn_fnc_toggle
 *
 * Public: No
 */

params ["_enabled"];

if (!isServer) exitWith {};

// To every player by remoteExec, taken only from the server (review S7).
[] remoteExecCall [[QFUNC(disable), QFUNC(enable)] select _enabled, 0];

nil
