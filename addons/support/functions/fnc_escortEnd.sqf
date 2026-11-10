#include "script_component.hpp"
/*
 * Author: YonV
 * Server: removes a lead's drone escorts - crew and airframe - at the end of
 * its sortie (DESIGN_SUPPORT_MESSAGING 1.2: they come home with it and are
 * recovered with it). A provider calls it with the lead when the sortie is
 * over and the lead is still there (a synced aircraft parked on its stand);
 * the watch calls it with the escorts when the lead was removed, or when they
 * are home after the lead was lost (FUNC(escortTick)).
 *
 * Wrecks are left where they fell. A delete lands only where the object
 * lives, so a drone a client took over is handed back first.
 *
 * Arguments:
 * 0: The lead, objNull when it is gone <OBJECT>
 * 1: Escorts to remove besides the lead's own (optional, default []) <ARRAY of OBJECTs>
 *
 * Return Value:
 * Escorts removed <NUMBER>
 *
 * Example:
 * [_veh] call jmfsb_support_fnc_escortEnd
 *
 * Public: Yes
 */

params [["_lead", objNull, [objNull]], ["_escorts", [], [[]]]];

if (!isServer) exitWith {0};

private _all = +_escorts;
if (!isNull _lead) then {
    _all append (_lead getVariable [QGVAR(escorts), []]);
    _lead setVariable [QGVAR(escorts), nil];
    _lead setVariable [QGVAR(escortShooter), nil];
};

private _gone = 0;
{
    if (!alive _x) then {continue};
    if (!local _x) then {_x setOwner SERVER_OWNER};
    private _veh = _x;
    {_veh deleteVehicleCrew _x} forEach (crew _veh);
    deleteVehicle _veh;
    _gone = _gone + 1;
} forEach (_all arrayIntersect _all);

if (_gone > 0) then {INFO_1("%1 escort(s) recovered",_gone)};

_gone
