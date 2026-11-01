#include "script_component.hpp"
/*
 * Author: JMSB
 * The driver's DEPLOY: an ACE progress bar for the deploy time (CBA setting,
 * 60 s by default), the vehicle held still and the driver in his seat; done,
 * the server swaps the baseplate for the gun (FUNC(deploy)). Moving or
 * leaving the seat cancels it and nothing changes.
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The driver <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, player] call jmfsb_artydeploy_fnc_deployStart
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if !([_veh, _unit, ACT_DEPLOY] call FUNC(canAct)) exitWith {};

[
    GVAR(time),
    [_veh, _unit],
    {
        (_this select 0) params ["_veh", "_unit"];
        [_veh, _unit] remoteExecCall [QFUNC(deploy), SERVER_OWNER];
    },
    {
        ["ARTILLERY", "Deploy stopped - the gun is not set up.", NOTE_WARN] call EFUNC(notify,notify);
    },
    "Deploying the gun...",
    {
        (_this select 0) params ["_veh", "_unit"];
        [_veh, _unit, ACT_DEPLOY] call FUNC(canAct)
    },
    ["isNotInside", "isNotSitting"]
] call ace_common_fnc_progressBar;
