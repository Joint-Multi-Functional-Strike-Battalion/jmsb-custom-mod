#include "script_component.hpp"
/*
 * Author: JMSB
 * The message box, painted from the same settings as the console.
 *
 * Separate from FUNC(style) only because it is a separate display - anyone may
 * open this one, admin or not, and it opens without the console behind it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_styleMessage
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_messageDisplayVar", displayNull];
if (isNull _display) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _opacity = ((missionNamespace getVariable [QEGVAR(tacpad,opacity), 0.92]) max 0.88) min 1;
private _base = [_ground # 0, _ground # 1, _ground # 2, _opacity];
private _lift = [
    ((_ground # 0) * 0.82) + ((_ink # 0) * 0.18),
    ((_ground # 1) * 0.82) + ((_ink # 1) * 0.18),
    ((_ground # 2) * 0.82) + ((_ink # 2) * 0.18),
    _opacity
];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

(_display displayCtrl IDC_ADMINMESSAGE_BACKGROUND) ctrlSetBackgroundColor _base;

// The wordmark, written here rather than in config - see ui\dialog.inc.hpp.
(_display displayCtrl IDC_ADMINMESSAGE_MAIN_TITLE) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='1.2' color='%1'>TAC//ADMIN  MESSAGE</t>",
    _ink call BIS_fnc_colorRGBAtoHTML
];
(_display displayCtrl IDC_ADMINMESSAGE_SEND_BUTTON_BACK) ctrlSetBackgroundColor _accent;
(_display displayCtrl IDC_ADMINMESSAGE_SEND_BUTTON) ctrlSetTextColor _ground;

{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetBackgroundColor _lift;
    _ctrl ctrlSetTextColor _ink;
} forEach [
    IDC_ADMINMESSAGE_PLAYER_SELECTOR,
    IDC_ADMINMESSAGE_MESSAGE_EDIT_BOX,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_HISTORY_LIST,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_BACKGROUND
];

{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetTextColor _ink};
} forEach [
    IDC_ADMINMESSAGE_MAIN_TITLE,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_HEADING,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_HISTORY_HEADING,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_SENDER,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_RECEIVER,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_MESSAGE_TEXT
];

{
    private _ctrl = _display displayCtrl _x;
    if (!isNull _ctrl) then {_ctrl ctrlSetTextColor _mute};
} forEach [
    IDC_ADMINMESSAGE_RECIPIENT_TEXT,
    IDC_ADMINMESSAGE_MESSAGE_VIEWER_MESSAGE_HEADING
];

// ON THE TABLET IT IS THE TABLET'S SCREEN, not the monitor and not the UI
// scale - see FUNC(fitHost).
if ([_display] call FUNC(fitHost)) exitWith {};

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
