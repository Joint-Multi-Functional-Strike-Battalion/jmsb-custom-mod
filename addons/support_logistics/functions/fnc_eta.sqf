#include "script_component.hpp"
/*
 * Author: YonV
 * How long until a delivery reaches its point: the leg in from the module -
 * its aircraft is made over the module the moment the request is accepted
 * (user, 2026-11-02: "all support aircraft needs to be virtual till tasked,
 * then they spawn in at alt over the support module location") - at
 * support_air's NORMAL speed estimate (EFUNC(support_air,flightTime)), the
 * same estimate every air row on the board gives. Read on the viewer's
 * machine from what the server published.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The delivery point <ARRAY>
 *
 * Return Value:
 * Seconds, ETA_UNKNOWN (-1) when the class has no top speed <NUMBER>
 *
 * Example:
 * [_logic, _pos] call jmfsb_support_logistics_fnc_eta
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_pos", [], [[]]]];

private _cls = _logic getVariable [QGVAR(cls), ""];
if (getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") <= 0 || count _pos < 2) exitWith {ETA_UNKNOWN};

(_logic getVariable [QGVAR(home), getPosATL _logic]) params ["_hx", "_hy"];

[_cls, [[_hx, _hy, 0], _pos], ETA_SPEED_NORMAL] call EFUNC(support_air,flightTime)
