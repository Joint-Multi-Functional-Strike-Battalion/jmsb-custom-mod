#include "script_component.hpp"
/*
 * Author: YonV
 * The driver's PACK: an ACE progress bar for the same time as the deploy, the
 * vehicle held still; done, the server takes the gun away (FUNC(undeploy)).
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The driver <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, player] call jmfsb_artydeploy_fnc_undeployStart
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if !([_veh, _unit, ACT_PACK] call FUNC(canAct)) exitWith {};

[
    GVAR(time),
    [_veh, _unit],
    {
        (_this select 0) params ["_veh", "_unit"];
        [_veh, _unit] remoteExecCall [QFUNC(undeploy), SERVER_OWNER];
    },
    {
        ["ARTILLERY", "Pack stopped - the gun is still up.", NOTE_WARN] call EFUNC(notify,notify);
    },
    "Packing the gun...",
    {
        (_this select 0) params ["_veh", "_unit"];
        [_veh, _unit, ACT_PACK] call FUNC(canAct)
    },
    ["isNotInside", "isNotSitting"]
] call ace_common_fnc_progressBar;
