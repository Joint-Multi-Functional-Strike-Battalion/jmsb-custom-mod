#include "..\script_component.hpp"
/*
 * Author: YonV
 * Server: one target on a pad - locked, empty, unarmed, warm on thermals.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Pad <OBJECT>
 *
 * Return Value:
 * The target <OBJECT>
 *
 * Public: No
 */

params [["_type", "", [""]], ["_pad", objNull, [objNull]]];

if (isNull _pad || {!isClass (configFile >> "CfgVehicles" >> _type)}) exitWith {
    WARNING_2("targetPads: cannot put %1 on %2",_type,_pad);
    objNull
};

private _target = createVehicle [_type, getPosATL _pad, [], 0, "CAN_COLLIDE"];
_target setDir getDir _pad;
_target setVehicleLock "LOCKED";
_target setVehicleAmmo 0;
_target setVehicleTIPars [1, 1, 1];
clearMagazineCargoGlobal _target;
clearWeaponCargoGlobal _target;
clearItemCargoGlobal _target;
clearBackpackCargoGlobal _target;
_target
