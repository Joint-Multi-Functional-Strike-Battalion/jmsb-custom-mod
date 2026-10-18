#include "..\script_component.hpp"
/*
 * Author: JMSB
 * A LandVehicle or Ship has been created (class InitPost, every machine). Asked
 * ONCE per vehicle, never again: is it air defence (FUNC(profile), cached per
 * class - anything that is not costs one lookup)?
 *
 *   server   registers it as an AD unit in its automatic alarm area: one per
 *            config side per ADS_AREA_CELL grid cell
 *   clients  give it the targeting-mode and mute actions
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_vehicle] call jmfsb_adsite_fnc_vehicleInit
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith {};
if (([_veh] call FUNC(profile)) isEqualTo [[], []]) exitWith {};

if (hasInterface) then { [_veh] call FUNC(actions) };

if (!isServer) exitWith {};
private _pos = getPosASL _veh;
private _key = format ["auto_%1_%2_%3", getNumber (configOf _veh >> "side"),
    floor ((_pos select 0) / ADS_AREA_CELL), floor ((_pos select 1) / ADS_AREA_CELL)];
[_veh, _key, -1, -1, false] call FUNC(register);
