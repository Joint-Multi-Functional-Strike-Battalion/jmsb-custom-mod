#include "script_component.hpp"
/*
 * Author: JMSB
 * Starts the rearm loop - once, whoever asks first. A SAM site that fired its
 * tubes dry and sat quiet for the rest of the mission read as broken, not
 * empty; every interval the surviving pieces of GVAR(hardware) come back to
 * full.
 *
 * Both builders ask: FUNC(start) for the ALiVE commanders' batteries, and
 * FUNC(buildAABase) for a hand-placed AA Base - a mission with only the AA
 * Base module would otherwise never rearm. The interval is the Air Defence
 * module's Rearm Every when that module set it, AD_REARM_DEFAULT minutes
 * otherwise; 0 switches rearming off.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_airdefence_fnc_rearmLoop
 *
 * Public: No
 */

if (!isServer) exitWith {};
if (!isNil QGVAR(rearmHandle)) exitWith {};

private _every = missionNamespace getVariable [QGVAR(rearmEvery), AD_REARM_DEFAULT];
if (_every <= 0) exitWith {
    GVAR(rearmHandle) = -1;
};

GVAR(rearmHandle) = [{
    {
        if (!isNull _x && {alive _x}) then { _x setVehicleAmmo 1 };
    } forEach GVAR(hardware);
}, _every * 60, []] call CBA_fnc_addPerFrameHandler;
