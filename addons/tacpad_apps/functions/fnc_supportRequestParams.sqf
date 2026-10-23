#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//SUPPORT: the parameter array a request carries, exactly as CONFIRM
 * TASKING sends it - the steppers' array, copied, with INGRESS and EGRESS in
 * slots 8 and 9 and every point the picked task declares (task declaration
 * field 7) in its own slot: one point, or a list for a row that takes
 * several; [] when unset, which the provider reads as its own choice. The
 * provider's preview (EFUNC(support,preview)) is asked with the same array,
 * so the verdict shown is about the request that would be sent.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The parameter array <ARRAY>
 *
 * Example:
 * private _prm = [] call jmfsb_tacpad_apps_fnc_supportRequestParams
 *
 * Public: No
 */

// 11 is the arty ordnance NAME, beside the index at 4.
#define PARAMS_MIN_COUNT 12

// Copied before it is extended: the stored array is the steppers'.
private _prm = +(missionNamespace getVariable [QGVAR(supportParams), SUP_PARAMS_DEFAULT]);
while {count _prm < PARAMS_MIN_COUNT} do {_prm pushBack []};
_prm set [SUP_PARAM_INGRESS, missionNamespace getVariable [QGVAR(supportIngress), []]];
_prm set [SUP_PARAM_EGRESS, missionNamespace getVariable [QGVAR(supportEgress), []]];

{
    _x params ["", "_dSlot", "", "", "", "", "_dKey"];
    while {count _prm <= _dSlot} do {_prm pushBack []};
    _prm set [_dSlot, +(missionNamespace getVariable [([_dKey] call FUNC(supportPointVars)) select 0, []])];
} forEach (uiNamespace getVariable [QGVAR(supportPointDecls), []]);

_prm
