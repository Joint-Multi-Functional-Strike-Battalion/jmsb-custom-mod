#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet's device bar (docs/DESIGN_TABLET.md, "Layout"): TAC//APP, the
 * time, "GRID <easting> <northing>" and callsign . group on the left; the
 * device right-aligned beside ESC CLOSES, which is in the accent
 * (art/images/tablet_screen.png). The vehicle tablet's device reads
 * "VEHICLE . <vehicle callsign>" (FUNC(vehicleName)).
 *
 * Redrawn only when one of those has changed - the key is the line itself.
 *
 * Arguments:
 * 0: The bar's body <CONTROL>
 * 1: The rows' last drawn keys <HASHMAP>
 *
 * Return Value:
 * Redrawn <BOOL>
 *
 * Example:
 * [_body, _keys] call jmfsb_devices_fnc_tabletBar
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_keys", createHashMap, [createHashMap]]];
if (isNull _body) exitWith {false};

private _device = (createHashMapFromArray DEVICE_NAMES) getOrDefault [GVAR(device), toUpper GVAR(device)];
if (GVAR(device) isEqualTo VEHICLE_DEVICE && {!isNull GVAR(vehicle)}) then {
    _device = format ["%1 %2 %3", _device, MIDDOT, [GVAR(vehicle)] call FUNC(vehicleName)];
};

// THE FACTS ARE EVERY DEVICE'S (FUNC(deviceFacts)): time, the GPS's grid (6
// or 10 figures, NO FIX when jammed, SUSPECT when the EW Receiver says so), who,
// the custom-channel gauge.
private _f = [] call FUNC(deviceFacts);
private _gridText = _f get "grid";
if ((_f get "gps") isEqualTo GPS_STATE_SUSPECT) then {_gridText = _gridText + " " + GPS_STATE_SUSPECT};
// THE CLOCK IN THE MIDDLE (user, 2026-10-30: "move time to center"): the grid
// and who to its left, the channels, nav and battery to its right.
private _clock = _f get "clock";
// Three spaces between facts, not six: with the clock in the middle each
// block has a third of the bar, and the wide gaps wrapped the facts under
// it (user, 2026-10-31: "wrapping?").
private _left = format ["GRID %1   %2", _gridText, _f get "who"];
private _right = [_f get "channels", _f getOrDefault ["nav", ""], _f getOrDefault ["batt", ""]] select {_x isNotEqualTo ""} joinString "   ";

private _key = str [_clock, _left, _right, _device];
if (_key isEqualTo (_keys getOrDefault ["bar", ""])) exitWith {false};
_keys set ["bar", _key];

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = _w * TABLET_GAP / TABLET_DESIGN_W;
private _brandW = _w * TABLET_BAR_BRAND_W;
private _escW = _w * TABLET_BAR_ESC_W;
private _menuW = _w * TABLET_BAR_MENU_W;
private _deviceW = _w * TABLET_BAR_DEVICE_W;
private _clockW = _w * TABLET_BAR_CLOCK_W;
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _text = +(["ground"] call EFUNC(tacpad,theme));
_text set [3, 1];

[_body, [_pad, 0, _brandW, _h], DEVICE_BRAND, _accent, TABLET_TEXT_BAR, true] call EFUNC(tacpad,drawText);
// The facts are numbers - time, grid, battery: the monospace. The left block
// runs from the brand to the clock, the right block from the clock to the
// device's name.
private _clockX = (_w - _clockW) * 0.5;
private _rightX = _clockX + _clockW + _pad;
private _deviceX = _w - _escW - _menuW - _deviceW - 3 * _pad;
[_body, [_pad + _brandW, 0, _clockX - _pad - _brandW - _pad, _h], _left, _text, TABLET_TEXT_BAR, true, "left", false, FONT_MONO] call EFUNC(tacpad,drawText);
[_body, [_clockX, 0, _clockW, _h], _clock, _text, TABLET_TEXT_BAR, true, "center", false, FONT_MONO] call EFUNC(tacpad,drawText);
[_body, [_rightX, 0, _deviceX - _rightX - _pad, _h], _right, _text, TABLET_TEXT_BAR, true, "left", false, FONT_MONO] call EFUNC(tacpad,drawText);
[_body, [_deviceX, 0, _deviceW, _h], _device, _text, TABLET_TEXT_BAR, true, "right"] call EFUNC(tacpad,drawText);
// MENU: every app and the settings, one press (user, 2026-10-30: "add a menu
// icon to get to each app and settings").
private _menuRect = [_w - _escW - _menuW - 2 * _pad, 0, _menuW, _h];
[_body, _menuRect, TABLET_BAR_MENU, _accent, TABLET_TEXT_BAR, true, "right"] call EFUNC(tacpad,drawText);
[_body, _menuRect, {[TABLET_MENU_APP, [], true] call EFUNC(tacpad,openApp)}] call EFUNC(tacpad,drawHit);
[_body, [_w - _escW - _pad, 0, _escW, _h], "ESC CLOSES", _accent, TABLET_TEXT_BAR, false, "right"] call EFUNC(tacpad,drawText);

true
