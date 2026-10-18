#include "script_component.hpp"
/*
 * Author: JMSB
 * Writes what the world is doing now at the top of the TIME / WEATHER dialog:
 * date, time and its speed; overcast, rain, fog and wind. Run every
 * ENV_READOUT_TICK by the handler FUNC(envLoad) starts, which goes when this
 * says the dialog is gone.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Dialog still open <BOOL>
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_envReadout
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable [QGVAR(envDisplay), displayNull];
if (isNull _display) exitWith {false};

date params ["_year", "_month", "_day"];

(_display displayCtrl IDC_ADMINENV_READOUT) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='0.9'>%1-%2-%3  %4  x%5</t><br/><t font='RobotoCondensed' size='0.75'>OVERCAST %6%10   RAIN %7%10   FOG %8%10   WIND %9 m/s</t>",
    _year,
    [_month, 2] call CBA_fnc_formatNumber,
    [_day, 2] call CBA_fnc_formatNumber,
    [dayTime, "HH:MM"] call BIS_fnc_timeToString,
    timeMultiplier,
    round (overcast * ENV_PERCENT),
    round (rain * ENV_PERCENT),
    round (fog * ENV_PERCENT),
    round (vectorMagnitude wind),
    "%"
];

true
