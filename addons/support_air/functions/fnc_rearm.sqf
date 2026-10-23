#include "script_component.hpp"
/*
 * Author: JMSB
 * A synced aircraft down on its stand at the end of a sortie: shut down,
 * repaired, refuelled and re-armed, its landing pad cleared and its crew
 * made whole again (FUNC(restoreCrew)) - ready for the next order, the way a
 * Simplex transport is reset on RTB.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh] call jmfsb_support_air_fnc_rearm
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if (!alive _veh) exitWith {};

_veh engineOn false;
_veh setDamage 0;
_veh setFuel 1;
_veh setVehicleAmmo 1;

private _pad = _veh getVariable [QGVAR(pad), objNull];
if (!isNull _pad) then {deleteVehicle _pad};

[_logic, _veh] call FUNC(restoreCrew);
