#include "script_component.hpp"
/*
 * Author: JMSB
 * A TIME / WEATHER quick button: puts dawn (sunrise), noon, dusk (sunset) or
 * midnight in the hour and minute combos. Only the combos - SET TIME applies.
 * Where the sun does not rise or set today, dawn and dusk give noon.
 *
 * Arguments:
 * 0: "dawn", "noon", "dusk" or "midnight" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["dawn"] call jmfsb_adminpanel_fnc_envTimeOf
 *
 * Public: No
 */

params [["_part", "", [""]]];

disableSerialization;
private _display = uiNamespace getVariable [QGVAR(envDisplay), displayNull];
if (isNull _display) exitWith {};

([] call BIS_fnc_sunriseSunsetTime) params ["_sunrise", "_sunset"];

private _hours = switch (_part) do {
    case "dawn": {_sunrise};
    case "dusk": {_sunset};
    case "noon": {ENV_NOON};
    default {0};
};
if (_hours < 0) then {_hours = ENV_NOON};

[_display displayCtrl IDC_ADMINENV_HOUR, floor _hours] call FUNC(envSelect);
[_display displayCtrl IDC_ADMINENV_MINUTE, (_hours % 1) * ENV_MINUTES_PER_HOUR] call FUNC(envSelect);
