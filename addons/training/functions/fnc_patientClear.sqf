#include "script_component.hpp"
/*
 * Author: YonV
 * Takes the training patient off a stretcher, or off every stretcher. Server
 * only.
 *
 * Arguments:
 * 0: Stretcher, objNull for all <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [objNull] call jmfsb_training_fnc_patientClear
 *
 * Public: No
 */

params [["_stretcher", objNull, [objNull]]];

if (!isServer) exitWith {};

private _which = if (isNull _stretcher) then {([] call FUNC(stretchers)) apply {_x # 1}} else {[_stretcher]};
{
    private _patient = _x getVariable [QGVAR(patient), objNull];
    if (!isNull _patient) then {deleteVehicle _patient};
    _x setVariable [QGVAR(patient), objNull, true];
} forEach _which;
