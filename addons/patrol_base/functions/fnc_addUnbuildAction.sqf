#include "script_component.hpp"
/*
 * Author: YonV
 * Adds the "Unbuild Patrol Base" action to a base beacon. Runs on every client
 * (remoteExec'd from the server, JIP-tied to the beacon). Any player within 3m
 * sees it.
 *
 * Arguments:
 * 0: Beacon <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_beacon", objNull, [objNull]]];
if !(hasInterface) exitWith {};
if (isNull _beacon) exitWith {};

_beacon addAction [
    "<t color='#ff5555'>Unbuild Patrol Base (recover kits)</t>",
    {
        params ["_target"];
        [_target] remoteExecCall [QFUNC(serverUnbuild), SERVER_OWNER];
        ["Patrol Base", "Unbuilding...", [1, 0.8, 0.3, 1]] call EFUNC(notify,notify);
    },
    nil,
    6,
    true,
    true,
    "",
    "alive _this",
    3
];
