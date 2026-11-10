#include "script_component.hpp"
/*
 * Author: YonV
 * Empties the code box and the return log.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_execClear
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

(_display displayCtrl IDC_ADMINPANEL_REMOTEEXEC_EDITBOX) ctrlSetText "";
lbClear (_display displayCtrl IDC_ADMINPANEL_REMOTEEXEC_RETURN);
