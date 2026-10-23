#include "script_component.hpp"
/*
 * Author: JMSB
 * The vehicle whose crew intercom (and vehicle set) a unit is on: a land
 * vehicle, aircraft or boat in which he holds a seat that is not cargo.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Vehicle, objNull when he is not crew <OBJECT>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_crewOf
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _vehicle = vehicle _unit;
if (isNull _unit || _vehicle isEqualTo _unit) exitWith {objNull};
if ((VEHICLE_KINDS findIf {_vehicle isKindOf _x}) < 0) exitWith {objNull};

private _crew = fullCrew _vehicle;
private _seat = _crew findIf {(_x select 0) isEqualTo _unit};
if (_seat < 0) exitWith {objNull};
if ((toLower ((_crew select _seat) select 1)) isEqualTo ROLE_CARGO) exitWith {objNull};

_vehicle
