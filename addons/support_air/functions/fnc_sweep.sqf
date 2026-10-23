#include "script_component.hpp"
/*
 * Author: JMSB
 * Removes an aircraft this addon made from a class, with its AI crew, any
 * AI still in the back and the landing pad it was given.
 *
 * NEVER WITH A PLAYER ABOARD. Deleting the crew under a man in the back of a
 * helicopter is a crash he did not ask for; the aircraft is left where it is
 * and the RPT says so. The transport waits for its passengers to get out
 * before it ever asks for this.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * Removed <BOOL>
 *
 * Example:
 * [_veh] call jmfsb_support_air_fnc_sweep
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith {true};

private _pad = _veh getVariable [QGVAR(pad), objNull];
if (!isNull _pad) then {deleteVehicle _pad};

if ((crew _veh) findIf {isPlayer _x} > -1) exitWith {
    WARNING_1("'%1' still has a player aboard - left in place",typeOf _veh);
    false
};

// A delete lands only where the object lives.
if (!local _veh) then {_veh setOwner 2};

{_veh deleteVehicleCrew _x} forEach (crew _veh);
deleteVehicle _veh;
true
