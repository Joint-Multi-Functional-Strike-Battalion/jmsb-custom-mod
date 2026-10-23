#include "script_component.hpp"
/*
 * Author: JMSB
 * InitPost of every drone40 variant of this addon. Only the machine that made
 * the drone acts: GX creates it where the round was fired, so there the
 * launcher is the local player (none on a dedicated server or a headless
 * client). After DEPLOY_DELAY_S - the object has reached the server and GX
 * has crewed it - the server is told (jmfsb_drone40_deployed).
 *
 * Arguments:
 * 0: Drone <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drone] call jmfsb_drone40_fnc_init
 *
 * Public: No
 */

params [["_drone", objNull, [objNull]]];

if (isNull _drone || {!local _drone}) exitWith {};

private _launcher = [objNull, player] select hasInterface;

[{
    params ["_drone", "_launcher"];
    if (isNull _drone || {!alive _drone}) exitWith {};
    [QGVAR(deployed), [_drone, _launcher]] call CBA_fnc_serverEvent;
}, [_drone, _launcher], DEPLOY_DELAY_S] call CBA_fnc_waitAndExecute;
