#include "script_component.hpp"
/*
 * Author: JMSB
 * Killed, on an FPV (FUNC(fpvWatch)): the wreck and its crew go
 * UAS_FPV_WRECK_S later (user, 2026-10-25: "despawn an exploded drone right
 * after it explodes"). The wait lets the other Killed handlers - the IED
 * Pelican's charge (FUNC(iedDrone)) - read where it was first.
 *
 * Arguments:
 * 0: The drone <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drone] call jmfsb_uas_fnc_fpvWreck
 *
 * Public: No
 */

params [["_drone", objNull, [objNull]]];

if (isNull _drone) exitWith {};
[{
    params ["_d"];
    if (isNull _d) exitWith {};
    deleteVehicleCrew _d;
    deleteVehicle _d;
}, [_drone], UAS_FPV_WRECK_S] call CBA_fnc_waitAndExecute;
