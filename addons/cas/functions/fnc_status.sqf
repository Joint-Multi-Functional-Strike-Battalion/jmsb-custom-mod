#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the support core's "status" hook (2026-11-09, STATUS in a drone's
 * thread - EFUNC(support,statusReply)): the drone, what it is doing and how
 * long it can stay. The core reads the grid, fuel, ammo and pax off the
 * drone itself.
 *
 *   task      the row's status, and the run's step in its thread - READBACK
 *             ASKED, WAITING FOR CLEARANCE, CLEARED, HOLDING FOR THE BDA
 *   minutes   the run's time left (its "until"); -1 with no run up
 *
 * Arguments:
 * 0: Asset id, "cas:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * [drone, task text, minutes left on station] <ARRAY>
 *
 * Example:
 * ["cas:0", "T0042"] call jmfsb_cas_fnc_status
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

private _logic = GVAR(entities) param [parseNumber ((_assetId splitString ":") param [1, "-1"]), objNull];
if (isNull _logic) exitWith {[objNull, "", STATUS_HOOK_NONE]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _run = _logic getVariable [QGVAR(run), createHashMap];
private _task = [toUpper _status, _why] select (_why isNotEqualTo "");
private _minutes = STATUS_HOOK_NONE;

if (alive _veh && {count _run > 0}) then {
    private _step = switch (true) do {
        case ((_run getOrDefault ["rb", ""]) isEqualTo RB_ASKED): {"READBACK ASKED"};
        case (_run getOrDefault ["struck", false]): {"HOLDING FOR THE BDA"};
        case (_logic getVariable [QGVAR(cleared), true]): {"CLEARED"};
        default {"WAITING FOR CLEARANCE"};
    };
    private _pos = _run getOrDefault ["pos", []];
    if (_pos isNotEqualTo []) then {_step = format ["%1 - %2", _step, mapGridPosition _pos]};
    _task = format ["%1 - %2", _task, _step];
    if ("until" in _run) then {_minutes = (((_run get "until") - CBA_missionTime) / SECONDS_PER_MINUTE) max 0};
};

[_veh, _task, _minutes]
