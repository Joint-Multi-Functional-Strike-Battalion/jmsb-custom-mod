#include "script_component.hpp"
/*
 * Author: JMSB
 * A TIME / WEATHER preset button: puts clear, cloudy, storm or fog in the four
 * weather combos. Only the combos - SET WEATHER applies.
 *
 * Arguments:
 * 0: "clear", "cloudy", "storm" or "foggy" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["storm"] call jmfsb_adminpanel_fnc_envPreset
 *
 * Public: No
 */

params [["_name", "", [""]]];

disableSerialization;
private _display = uiNamespace getVariable [QGVAR(envDisplay), displayNull];
if (isNull _display) exitWith {};

private _values = switch (_name) do {
    case "clear": {ENV_PRESET_CLEAR};
    case "cloudy": {ENV_PRESET_CLOUDY};
    case "storm": {ENV_PRESET_STORM};
    default {ENV_PRESET_FOGGY};
};

{
    [_display displayCtrl _x, _values select _forEachIndex] call FUNC(envSelect);
} forEach [IDC_ADMINENV_OVERCAST, IDC_ADMINENV_RAIN, IDC_ADMINENV_FOG, IDC_ADMINENV_WIND];
