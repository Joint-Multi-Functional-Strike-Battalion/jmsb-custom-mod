#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function enables spectator functionality.
 *
 * Server only: each player who may spectate gets FUNC(start) by remoteExec,
 * which takes it only from the server (review R1: it was a CBA event any
 * client could raise to force every player into spectator).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: New spectator state <BOOL>
 *
 * Example:
 * [1] call jmfsb_spectator_fnc_enable
 *
 * Public: No
 */

if (!isServer) exitWith {false};

{
    [_x] remoteExecCall [QFUNC(start), _x];
} forEach (allPlayers select {[_x] call FUNC(canSpectate)});

true
