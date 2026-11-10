#include "script_component.hpp"
/*
 * Author: YonV
 * The SECRETS dialog's onLoad (code review R4, 2026-10-31): paints it as
 * TIME / WEATHER is painted, names the rows, and asks the server which secrets
 * are set (jmfsb_common_fnc_secretStatus answers FUNC(secretsShow)). Until
 * the answer, each row says ASKING.
 *
 * Arguments:
 * 0: The dialog <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_adminpanel_fnc_secretsLoad
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};
uiNamespace setVariable [QGVAR(secretsDisplay), _display];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];
private _opacity = ((missionNamespace getVariable [QEGVAR(tacpad,opacity), 0.92]) max 0.88) min 1;
private _lift = [
    ((_ground # 0) * 0.82) + ((_ink # 0) * 0.18),
    ((_ground # 1) * 0.82) + ((_ink # 1) * 0.18),
    ((_ground # 2) * 0.82) + ((_ink # 2) * 0.18),
    _opacity
];
private _html = _ink call BIS_fnc_colorRGBAtoHTML;

(_display displayCtrl IDC_ADMINSECRETS_BACKGROUND) ctrlSetBackgroundColor [_ground # 0, _ground # 1, _ground # 2, _opacity];
(_display displayCtrl IDC_ADMINSECRETS_TITLE) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='1.2' color='%1'>TAC//ADMIN  SECRETS</t>", _html
];
(_display displayCtrl IDC_ADMINSECRETS_NOTE) ctrlSetTextColor _ink;

{
    (_display displayCtrl (IDC_ADMINSECRETS_LABEL + _forEachIndex)) ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensedBold' size='0.75' color='%1'>%2</t>", _html, _x
    ];
    (_display displayCtrl (IDC_ADMINSECRETS_STATUS + _forEachIndex)) ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensed' size='0.75' align='right' color='%1'>ASKING</t>", _html
    ];
    private _edit = _display displayCtrl (IDC_ADMINSECRETS_EDIT + _forEachIndex);
    _edit ctrlSetBackgroundColor _lift;
    _edit ctrlSetTextColor _ink;
    private _set = _display displayCtrl (IDC_ADMINSECRETS_SET + _forEachIndex);
    _set ctrlSetBackgroundColor _accent;
    _set ctrlSetTextColor _ground;
} forEach SECRET_LABELS;

private _close = _display displayCtrl IDC_ADMINSECRETS_CLOSE;
_close ctrlSetBackgroundColor _lift;
_close ctrlSetTextColor _ink;

[] remoteExecCall [QEFUNC(common,secretStatus), ADMIN_SERVER];
