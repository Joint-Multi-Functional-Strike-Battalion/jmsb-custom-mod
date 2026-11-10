#include "script_component.hpp"
/*
 * Author: YonV
 * A vehicle in the burst's near field loses its sensors and its datalink
 * for the jam duration (runs where the vehicle is local), then gets back
 * exactly what it had.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Seconds <NUMBER>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_dur", 5, [0]]];
if (isNull _veh || {!local _veh} || _dur <= 0) exitWith {};
if (_veh getVariable [QGVAR(blackedOut), false]) exitWith {};
_veh setVariable [QGVAR(blackedOut), true];

private _sensors = (listVehicleSensors _veh) select { _x isEqualType [] && {_x param [1, true]} } apply { _x select 0 };
private _report = vehicleReportRemoteTargets _veh;
private _receive = vehicleReceiveRemoteTargets _veh;

{ _veh enableVehicleSensor [_x, false] } forEach _sensors;
_veh setVehicleReportRemoteTargets false;
_veh setVehicleReceiveRemoteTargets false;

[{
    params ["_veh", "_sensors", "_report", "_receive"];
    if (isNull _veh) exitWith {};
    { _veh enableVehicleSensor [_x, true] } forEach _sensors;
    _veh setVehicleReportRemoteTargets _report;
    _veh setVehicleReceiveRemoteTargets _receive;
    _veh setVariable [QGVAR(blackedOut), false];
}, [_veh, _sensors, _report, _receive], _dur] call CBA_fnc_waitAndExecute;
