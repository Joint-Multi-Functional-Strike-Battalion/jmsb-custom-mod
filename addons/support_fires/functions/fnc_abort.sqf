#include "script_component.hpp"
/*
 * Author: YonV
 * A recall (the support page's RTB), on the server, reached by remoteExec
 * from FUNC(task). Only the sender may recall, and only his own side's
 * asset that is on a mission (FUNC(requester), FUNC(check); review S6) - no
 * client can stop another side's fires.
 *
 *   artillery         - CHECK FIRE: rounds not yet fired are not fired; those
 *                       in the air still land. Every battery that joined the
 *                       mission (coordinated) checks fire with it.
 *   loitering munitions - every munition airborne self-destructs where it is
 *   cruise missiles   - refused before it gets here (FUNC(task))
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_logic] remoteExecCall ["jmfsb_support_fires_fnc_abort", 2]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};

private _requester = [_logic] call FUNC(requester);
if (isNull _requester) exitWith {};
([_logic, TASK_RTB, [], [], _requester] call FUNC(check)) params ["_ok", "_why"];
if (!_ok) exitWith {
    INFO_2("abort: refused for %1 - %2",_requester,_why);
    [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], false, _why, _requester] call EFUNC(support,ack);
};

_logic setVariable [QGVAR(abort), true, true];

switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {
        {
            _x params ["_partner", "_pToken"];
            [_partner, _pToken, "check fire - rounds in the air will still land"] call FUNC(finish);
        } forEach (_logic getVariable [QGVAR(partners), []]);
        [_logic, _logic getVariable [QGVAR(token), -1], "check fire - rounds in the air will still land"] call FUNC(finish);
    };
    case TYPE_LOITER: {
        [_logic, "abort - munitions self-destructing", "normal"] call FUNC(say);
    };
    default {};
};
