#include "script_component.hpp"
/*
 * Author: JMSB
 * Where a walking-view device and its screen land on this monitor.
 *
 * THE SAME RULES AS FUNC(layout), AT A DIFFERENT SIZE AND PLACE. The body
 * rectangle from CfgJmfsbDevices - not the square canvas round it - is what
 * is sized: to the player's phoneFill slider for the phone, to the player's
 * slider for a side device. The canvas side is found in pixels and converted
 * with pixelW and pixelH so the square texture is drawn square; a UI unit is
 * not the same length across as down, and a device sized in units shears.
 *
 * WHERE IT GOES. The phone sits bottom centre, its body a margin off the
 * bottom of the safe zone. A side device sits against the left or right edge,
 * vertically centred - Micro DAGR style - and which edge is the player's
 * choice, kept in his profile (GVAR(overlayEdge), set by FUNC(overlaySetEdge)
 * from the tablet's SETTINGS > DEVICES or a walking-view button).
 *
 * Arguments:
 * 0: Device class in CfgJmfsbDevices <STRING>
 * 1: Edge for a side device - "left" or "right"; ignored for the phone <STRING> (optional, default "right")
 *
 * Return Value:
 * 0: Frame position [x, y, w, h] <ARRAY>
 * 1: Screen position [x, y, w, h] <ARRAY>
 * 2: Frame texture path, "" when the device is unknown <STRING>
 *
 * Example:
 * (["side", "left"] call jmfsb_devices_fnc_overlayLayout) params ["_framePos", "_screenPos", "_texture"]
 *
 * Public: Yes
 */

params [["_device", "phone", [""]], ["_edge", "right", [""]]];

private _cfg = configFile >> "CfgJmfsbDevices" >> _device;
if (!isClass _cfg) exitWith {
    WARNING_1("overlayLayout: no device '%1' in CfgJmfsbDevices",_device);
    [[0, 0, 0, 0], [0, 0, 0, 0], ""]
};

(getArray (_cfg >> "body")) params ["_bx", "_by", "_bw", "_bh"];
(getArray (_cfg >> "screen")) params ["_sx", "_sy", "_sw", "_sh"];

private _phone = _device isEqualTo "phone";
private _fill = [GVAR(sideFill), GVAR(phoneFill)] select _phone;

// The body's height in pixels, and the canvas side that gives it - capped by
// the monitor's width so an absurd slider on a narrow screen cannot push the
// device off both sides at once.
private _availW = safeZoneW / pixelW;
private _availH = (safeZoneH / pixelH) * (_fill max 0.1);
private _side = (_availH / _bh) min (_availW / _bw);
private _cw = _side * pixelW;
private _ch = _side * pixelH;

private _marginX = OVERLAY_MARGIN * safeZoneW;
private _marginY = OVERLAY_MARGIN * safeZoneH;

private _x0 = 0;
private _y0 = 0;
if (_phone) then {
    // Bottom centre: the body's centre on the monitor's, its bottom edge a
    // margin up from the safe zone's.
    _x0 = safeZoneX + safeZoneW / 2 - (_bx + _bw / 2) * _cw;
    _y0 = safeZoneY + safeZoneH - _marginY - (_by + _bh) * _ch;
} else {
    // Against the chosen edge, centred vertically.
    _x0 = if (_edge isEqualTo "left") then {
        safeZoneX + _marginX - _bx * _cw
    } else {
        safeZoneX + safeZoneW - _marginX - (_bx + _bw) * _cw
    };
    _y0 = safeZoneY + safeZoneH / 2 - (_by + _bh / 2) * _ch;
};

[
    [_x0, _y0, _cw, _ch],
    [_x0 + _sx * _cw, _y0 + _sy * _ch, _sw * _cw, _sh * _ch],
    getText (_cfg >> "frame")
]
