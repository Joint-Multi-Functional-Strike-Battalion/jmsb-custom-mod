#include "script_component.hpp"
/*
 * Author: YonV
 * May this player do this step of the deploy cycle on this carrier now? He
 * must be its driver - or, to pack a gun, its driver who has climbed out and
 * is near the gun - and it must be standing still.
 *
 *   pre     no spot marked and no gun up        mark the spot (baseplate)
 *   clear   a spot marked                       take the baseplate away
 *   deploy  a spot marked, no gun up            set the gun up on it
 *   pack    a gun up                            pack it away
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 * 1: The player <OBJECT>
 * 2: Step - ACT_PRE, ACT_CLEAR, ACT_DEPLOY or ACT_PACK <STRING>
 *
 * Return Value:
 * Allowed <BOOL>
 *
 * Example:
 * [_veh, player, "deploy"] call jmfsb_artydeploy_fnc_canAct
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_unit", objNull, [objNull]], ["_step", "", [""]]];

if (isNull _veh || {!alive _veh} || {!alive _unit}) exitWith {false};
if (driver _veh isNotEqualTo _unit) exitWith {false};
if (speed _veh > STOPPED_SPEED || {speed _veh < -STOPPED_SPEED}) exitWith {false};

private _plate = _veh getVariable [QGVAR(plate), objNull];
private _gun = _veh getVariable [QGVAR(gun), objNull];

switch (_step) do {
    case ACT_PRE: {isNull _plate && {isNull _gun}};
    case ACT_CLEAR: {!isNull _plate};
    case ACT_DEPLOY: {!isNull _plate && {isNull _gun}};
    case ACT_PACK: {!isNull _gun};
    default {false};
}
