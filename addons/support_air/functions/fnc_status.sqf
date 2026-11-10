#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the support core's "status" hook (2026-11-09, STATUS in an asset's
 * thread - EFUNC(support,statusReply)): the aircraft, what it is doing and
 * how long it can stay. The core reads the grid, fuel, ammo and pax off the
 * aircraft itself.
 *
 *   task      the module's status, with the lift job's step on a transport
 *             or a QRF lift (FUNC(liftReply)'s JOB_ words), else why it is
 *             not available
 *   minutes   a CAS sortie's time left on station (its "until"); -1 for
 *             anything else
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * [vehicle, task text, minutes left on station] <ARRAY>
 *
 * Example:
 * ["air:0", "T0042"] call jmfsb_support_air_fnc_status
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[objNull, "", -1]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
private _task = [toUpper _status, _why] select (_why isNotEqualTo "");
if (count _job > 0) then {
    _task = format ["%1 - %2", toUpper (_job getOrDefault ["kind", ""]), toUpper (_job getOrDefault ["step", ""])];
};

private _minutes = -1;
if ((_logic getVariable [QGVAR(kind), ""]) isEqualTo KIND_CAS) then {
    private _st = _logic getVariable [QGVAR(sortieState), createHashMap];
    if ("until" in _st) then {_minutes = (((_st get "until") - CBA_missionTime) / SECONDS_PER_MINUTE) max 0};
};

[_veh, _task, _minutes]
