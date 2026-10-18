#include "script_component.hpp"
/*
 * Author: JMSB
 * The TIME / WEATHER dialog's onLoad: fills every combo, picks in each the
 * value the world has now, paints the dialog from the tacpad's scheme the way
 * FUNC(styleMessage) paints the message box, and starts the readout.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_adminpanel_fnc_envLoad
 *
 * Public: No
 */

params ["_display"];

disableSerialization;
uiNamespace setVariable [QGVAR(envDisplay), _display];

// --- The combos, as [text, value] rows -------------------------------------
private _fnc_fill = {
    params ["_idc", "_rows", "_pick"];
    private _ctrl = _display displayCtrl _idc;
    lbClear _ctrl;
    {
        _x params ["_text", "_value"];
        _ctrl lbSetValue [_ctrl lbAdd _text, _value];
    } forEach _rows;
    [_ctrl, _pick] call FUNC(envSelect);
};

private _hours = [];
for "_h" from 0 to 23 do {
    _hours pushBack [[_h, 2] call CBA_fnc_formatNumber, _h];
};
private _minutes = [];
for "_m" from 0 to (ENV_MINUTES_PER_HOUR - ENV_MINUTE_STEP) step ENV_MINUTE_STEP do {
    _minutes pushBack [[_m, 2] call CBA_fnc_formatNumber, _m];
};
private _percents = [];
for "_p" from 0 to ENV_PERCENT step ENV_PERCENT_STEP do {
    _percents pushBack [format ["%1%2", _p, "%"], _p];
};
private _winds = [];
for "_w" from 0 to ENV_WIND_MAX step ENV_WIND_STEP do {
    _winds pushBack [format ["%1 m/s", _w], _w];
};

[IDC_ADMINENV_HOUR, _hours, floor dayTime] call _fnc_fill;
[IDC_ADMINENV_MINUTE, _minutes, floor ((dayTime % 1) * ENV_MINUTES_PER_HOUR)] call _fnc_fill;
[IDC_ADMINENV_SPEED, ENV_SPEEDS apply {[format ["x%1", _x], _x]}, timeMultiplier] call _fnc_fill;
[IDC_ADMINENV_OVERCAST, _percents, overcast * ENV_PERCENT] call _fnc_fill;
[IDC_ADMINENV_RAIN, _percents, rain * ENV_PERCENT] call _fnc_fill;
[IDC_ADMINENV_FOG, _percents, fog * ENV_PERCENT] call _fnc_fill;
[IDC_ADMINENV_WIND, _winds, vectorMagnitude wind] call _fnc_fill;

// --- The paint, as FUNC(styleMessage) does it --------------------------------
([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];

private _opacity = ((missionNamespace getVariable [QEGVAR(tacpad,opacity), 0.92]) max 0.88) min 1;
private _lift = [
    ((_ground # 0) * 0.82) + ((_ink # 0) * 0.18),
    ((_ground # 1) * 0.82) + ((_ink # 1) * 0.18),
    ((_ground # 2) * 0.82) + ((_ink # 2) * 0.18),
    _opacity
];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

(_display displayCtrl IDC_ADMINENV_BACKGROUND) ctrlSetBackgroundColor [_ground # 0, _ground # 1, _ground # 2, _opacity];
(_display displayCtrl IDC_ADMINENV_TITLE) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='1.2' color='%1'>TAC//ADMIN  TIME / WEATHER</t>",
    _ink call BIS_fnc_colorRGBAtoHTML
];

{
    private _ctrl = _display displayCtrl _x;
    _ctrl ctrlSetBackgroundColor _lift;
    _ctrl ctrlSetTextColor _ink;
} forEach [
    IDC_ADMINENV_HOUR, IDC_ADMINENV_MINUTE, IDC_ADMINENV_SPEED,
    IDC_ADMINENV_OVERCAST, IDC_ADMINENV_RAIN, IDC_ADMINENV_FOG, IDC_ADMINENV_WIND,
    IDC_ADMINENV_DAWN, IDC_ADMINENV_NOON, IDC_ADMINENV_DUSK, IDC_ADMINENV_MIDNIGHT,
    IDC_ADMINENV_CLEAR, IDC_ADMINENV_CLOUDY, IDC_ADMINENV_STORM, IDC_ADMINENV_FOGGY,
    IDC_ADMINENV_CLOSE
];

{
    private _ctrl = _display displayCtrl _x;
    _ctrl ctrlSetBackgroundColor _accent;
    _ctrl ctrlSetTextColor _ground;
} forEach [IDC_ADMINENV_TIME_APPLY, IDC_ADMINENV_WEATHER_APPLY];

{
    (_display displayCtrl _x) ctrlSetTextColor _ink;
} forEach [IDC_ADMINENV_READOUT, IDC_ADMINENV_TIME_HEAD, IDC_ADMINENV_WEATHER_HEAD];

{
    (_display displayCtrl _x) ctrlSetTextColor _mute;
} forEach [
    IDC_ADMINENV_HOUR_LABEL, IDC_ADMINENV_MINUTE_LABEL, IDC_ADMINENV_SPEED_LABEL,
    IDC_ADMINENV_OVERCAST_LABEL, IDC_ADMINENV_RAIN_LABEL, IDC_ADMINENV_FOG_LABEL,
    IDC_ADMINENV_WIND_LABEL, IDC_ADMINENV_NOTE
];

// --- The readout, once now and then every tick while the dialog is up --------
[] call FUNC(envReadout);
[{
    if !([] call FUNC(envReadout)) then {[_this select 1] call CBA_fnc_removePerFrameHandler};
}, ENV_READOUT_TICK, []] call CBA_fnc_addPerFrameHandler;

// --- UI size, as the console and the message box take it --------------------
private _scale = missionNamespace getVariable [QEGVAR(tacpad,uiScale), 1];
if (_scale isEqualTo 1) exitWith {};

private _cx = safeZoneX + safeZoneW / 2;
private _cy = safeZoneY + safeZoneH / 2;
private _fontBase = 0.8 * (0.025 * safeZoneH);

{
    (ctrlPosition _x) params ["_x0", "_y0", "_w0", "_h0"];
    _x ctrlSetPosition [
        _cx + (_x0 - _cx) * _scale,
        _cy + (_y0 - _cy) * _scale,
        _w0 * _scale,
        _h0 * _scale
    ];
    _x ctrlSetFontHeight (_fontBase * _scale);
    _x ctrlCommit 0;
} forEach (allControls _display);
