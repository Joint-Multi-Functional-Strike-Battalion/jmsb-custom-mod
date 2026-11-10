#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the support core's "status" hook (2026-11-09, STATUS in a jump
 * thread - EFUNC(support,statusReply)): the run's aircraft (the core reads its
 * grid, fuel and the men aboard) and the run's type, phase and pass.
 *
 * Arguments:
 * 0: Asset id, "jump:<n>" <STRING>
 * 1: Thread id <STRING>
 *
 * Return Value:
 * [vehicle, task text, minutes left on station (-1)] <ARRAY>
 *
 * Example:
 * ["jump:0", "T0042"] call jmfsb_jumpmaster_fnc_status
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]]];

private _at = GVAR(runs) findIf {(_x get "thread") isEqualTo _threadId};
if (_at < 0) exitWith {
    private _logic = ([_assetId] call FUNC(asset)) getOrDefault ["logic", objNull];
    private _veh = objNull;
    if (!isNull _logic) then {_veh = _logic getVariable [QGVAR(veh), objNull]};
    [_veh, STATUS_IDLE_WORD, -1]
};

private _st = GVAR(runs) select _at;
private _veh = _st get "veh";
if (isNull _veh && {!isNull (_st get "logic")}) then {_veh = (_st get "logic") getVariable [QGVAR(veh), objNull]};
[_veh, format [STATUS_RUN, _st get "type", toUpper (_st get "phase"), (_st get "pass") + 1, _st get "passes", count ([_st] call FUNC(aboard))], -1]
