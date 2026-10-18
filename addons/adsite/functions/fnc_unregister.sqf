#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Drops a vehicle from the AD units, on its Deleted or Killed event. Dead
 * units another machine owns (whose Killed does not fire here) are skipped by
 * every alive check and dropped the same way when they are deleted.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_vehicle] call jmfsb_adsite_fnc_unregister
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

private _key = hashValue _veh;
private _rec = GVAR(units) get _key;
if (isNil "_rec") exitWith {};

GVAR(units) deleteAt _key;
private _area = GVAR(areas) get (_rec select U_AREA);
if (!isNil "_area") then { _area set [0, (_area select 0) - [_key]] };

if (count GVAR(units) == 0) then {
    missionNamespace setVariable [QGVAR(armed), false, true];
};
