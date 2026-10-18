#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Takes the tube mask down.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_nvg_fnc_maskHide
 *
 * Public: No
 */

private _ctrl = uiNamespace getVariable [QGVAR(mask), controlNull];
if (!isNull _ctrl) then {ctrlDelete _ctrl};

uiNamespace setVariable [QGVAR(mask), controlNull];
