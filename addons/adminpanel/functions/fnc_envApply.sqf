#include "script_component.hpp"
/*
 * Author: JMSB
 * SET TIME or SET WEATHER: reads the combos and raises the event that changes
 * the world - time on the server (FUNC(envTime)), weather on every machine
 * (FUNC(envWeather)), the way ZEN's weather module does it. CBA events, so no
 * CfgRemoteExec entry is needed.
 *
 * Arguments:
 * 0: "time" or "weather" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["time"] call jmfsb_adminpanel_fnc_envApply
 *
 * Public: No
 */

params [["_what", "", [""]]];

disableSerialization;
private _display = uiNamespace getVariable [QGVAR(envDisplay), displayNull];
if (isNull _display) exitWith {};

private _fnc_value = {
    params ["_idc"];
    private _ctrl = _display displayCtrl _idc;
    _ctrl lbValue ((lbCurSel _ctrl) max 0)
};

if (_what isEqualTo "time") exitWith {
    private _hour = [IDC_ADMINENV_HOUR] call _fnc_value;
    private _minute = [IDC_ADMINENV_MINUTE] call _fnc_value;
    private _speed = [IDC_ADMINENV_SPEED] call _fnc_value;

    [QGVAR(envTime), [_hour, _minute, _speed, profileName]] call CBA_fnc_serverEvent;
    ["Time", format [
        "Set to %1:%2, time x%3",
        [_hour, 2] call CBA_fnc_formatNumber,
        [_minute, 2] call CBA_fnc_formatNumber,
        _speed
    ]] call EFUNC(notify,notify);
};

private _overcast = [IDC_ADMINENV_OVERCAST] call _fnc_value;
private _rain = [IDC_ADMINENV_RAIN] call _fnc_value;
private _fog = [IDC_ADMINENV_FOG] call _fnc_value;
private _wind = [IDC_ADMINENV_WIND] call _fnc_value;

[QGVAR(envWeather), [
    _overcast / ENV_PERCENT, _rain / ENV_PERCENT, _fog / ENV_PERCENT, _wind, profileName
]] call CBA_fnc_globalEvent;
["Weather", format [
    "Overcast %1%5, rain %2%5, fog %3%5, wind %4 m/s",
    _overcast, _rain, _fog, _wind, "%"
]] call EFUNC(notify,notify);
