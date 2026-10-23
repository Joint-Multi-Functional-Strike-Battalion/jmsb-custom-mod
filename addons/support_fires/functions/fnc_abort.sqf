#include "script_component.hpp"
/*
 * Author: JMSB
 * A recall (the support page's RTB), on the server.
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
 * [_logic] call jmfsb_support_fires_fnc_abort
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isEqualTo STATUS_IDLE) exitWith {};

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
        [QGVAR(say), [_logic, "abort - munitions self-destructing", "normal"]] call CBA_fnc_globalEvent;
    };
    default {};
};
