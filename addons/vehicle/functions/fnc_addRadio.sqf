#include "script_component.hpp"
/*
 * Author: SGT.Brostrom.A
 * This function changes the inventory of the given vehicle.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * nothing
 *
 * Example:
 * [_vehicle] call ymf_fnc_vehicle_addRadio;
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];

if (!isServer) exitWith {};
// ACRE racks only. Under game voice a vehicle is the VEH net (crew intercom,
// jmfsb_voice) and needs nothing put in it.
if (!EGVAR(Patches,usesACRE)) exitWith {};
if (!EGVAR(Settings,enableRadios)) exitWith {};
if (!EGVAR(Settings,enableVehicleRadios)) exitWith {};


if (!isMultiplayer) exitWith {SHOW_WARNING_2("VehicleRadio","Vehicle rack initialisation for %1 [%2] is stopped due to being in a SP environment.",_vehicle,typeOf _vehicle);};

if (!isNil{_vehicle getVariable QEGVAR(VehicleFunc,Radio);}) exitWith {SHOW_WARNING_2("VehicleRadio","Vehicle radios already applied for %1 [%2].",_vehicle,typeOf _vehicle);};
if (!(_vehicle call EFUNC(systems,isValidFaction))) exitWith {};

// If ACRE wait for init
if (EGVAR(patches,usesACRE)) then { waitUntil {EGVAR(gear,Radio) && [] call acre_api_fnc_isInitialized}; };

TRACE_INFO_2("VehicleRadio","Applying vehicle radios to %1 (%2)",_vehicle,typeOf _vehicle);

// EVERY VEHICLE OF OURS, NOT FOUR HULLS (user, 2026-09-02). This used to name
// the MRAP, the HEMTT and two fast jets and silently pass over everything else -
// so the tanks, the helicopters, the boats and the LSVs had no racks and no
// radios at all. The gate on who counts as ours is above and unchanged
// (fn_isValidFaction, the vehicleFactions setting): OUR BLUE AND NOBODY ELSE,
// which is what keeps this off the several hundred vehicles ALiVE spawns.
//
// The fast jets keep their own channel pair; everything else takes the ground
// default. Racked 117Fs ignore both and go to the detachment net - see
// fn_setRadio.
private _channels = [1];
if (_vehicle isKindOf "Plane_Fighter_03_base_F" || {_vehicle isKindOf "Plane_CAS_01_base_F"}) then {
    _channels = [10,11];
};

[_vehicle, _channels] call EFUNC(vehicle,setRadio);

_vehicle setVariable [QEGVAR(VehicleFunc,Radio), true, true];
