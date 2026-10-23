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
private _facts = format ["%1      GRID %2      %3      %4", _f get "clock", _gridText, _f get "who", _f get "channels"];

private _key = str [_facts, _device];
if (_key isEqualTo (_keys getOrDefault ["bar", ""])) exitWith {false};
_keys set ["bar", _key];

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = _w * TABLET_GAP / TABLET_DESIGN_W;
private _brandW = _w * TABLET_BAR_BRAND_W;
private _escW = _w * TABLET_BAR_ESC_W;
private _deviceW = _w * TABLET_BAR_DEVICE_W;
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _text = +(["ground"] call EFUNC(tacpad,theme));
_text set [3, 1];

[_body, [_pad, 0, _brandW, _h], DEVICE_BRAND, _accent, TABLET_TEXT_BAR, true] call EFUNC(tacpad,drawText);
[_body, [_pad + _brandW, 0, _w - _brandW - _deviceW - _escW - 3 * _pad, _h], _facts, _text, TABLET_TEXT_BAR, true] call EFUNC(tacpad,drawText);
[_body, [_w - _escW - _deviceW - 2 * _pad, 0, _deviceW, _h], _device, _text, TABLET_TEXT_BAR, true, "right"] call EFUNC(tacpad,drawText);
[_body, [_w - _escW - _pad, 0, _escW, _h], "ESC CLOSES", _accent, TABLET_TEXT_BAR, false, "right"] call EFUNC(tacpad,drawText);

true
