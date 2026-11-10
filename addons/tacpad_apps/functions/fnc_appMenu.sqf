#include "script_component.hpp"
/*
 * Author: YonV
 * THE MENU (user, 2026-10-30: "add a menu icon to get to each app and
 * settings"; the tablet bar's MENU word opens it): every app the tiles know,
 * in the band's order, then the apps of the tiles switched off, then the
 * app that has no tile (TAC//PAC), then SETTINGS - one row
 * each, a press opens it. A way into every app that does
 * not need its tile on screen: a tile switched off, or on a page the band is
 * not showing. The MSG tile is the reader, not an app, and is not listed.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_tacpad_apps_fnc_appMenu
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

private _choices = [] call FUNC(tileChoices);
// The apps with no tile any more come after the tiles' (user, 2026-11-01).
private _names = createHashMapFromArray (_choices + MENU_APPS_NO_TILE);
private _handlers = EGVAR(tacpad,appHandlers);
private _ids = ([_choices apply {_x # 0}] call FUNC(tileOrder)) select {_x in _handlers};
{
    if (_x in _handlers) then {_ids pushBackUnique _x};
} forEach ((_choices + MENU_APPS_NO_TILE) apply {_x # 0});
private _rows = (_ids apply {[_x, _names getOrDefault [_x, toUpper _x]]}) + [[MENU_SETTINGS_APP, MENU_SETTINGS_NAME]];

// Measured, then opened: the rows, the pads and the frame's own chrome, held
// to the screen - past that the body scrolls.
private _rowH = ROW_H_SCREEN;
private _padY = PAD * HOST_H;
private _chrome = HEADER_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H + (RULE_THICK * pixelH) * 3;
private _needed = ((count _rows) * _rowH + 2 * _padY + _chrome) / HOST_H;
([_display, "MENU", MENU_APP_W, _needed min MENU_APP_H_MAX, _needed > MENU_APP_H_MAX] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

{
    _x params ["_app", "_name"];
    private _ctrl = [_body, _forEachIndex, _name, "", [], false, {
        params ["", "_ctrl"];
        private _app = _ctrl getVariable [QGVAR(menuApp), ""];
        if (_app isEqualTo "") exitWith {};
        [_app, [], true] call EFUNC(tacpad,openApp);
    }] call FUNC(row);
    _ctrl setVariable [QGVAR(menuApp), _app];
} forEach _rows;
