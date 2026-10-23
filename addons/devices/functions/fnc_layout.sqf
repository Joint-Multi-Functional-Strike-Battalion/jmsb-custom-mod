#include "script_component.hpp"
/*
 * Author: JMSB
 * Where one device and its screen land on this monitor.
 *
 * THE DEVICE FILLS THE SCREEN, NOT THE TEXTURE. A frame texture is a square
 * canvas with transparent padding round the device - the large tablet is 64% of
 * its canvas tall - so fitting the canvas to the monitor would draw the device
 * at two thirds of the height it could have. The body rectangle from
 * CfgJmfsbDevices is what is fitted, on whichever axis runs out first, and the
 * canvas lands wherever that puts it, padding off the edges of the monitor.
 *
 * SQUARE ON SCREEN. The texture is square and must be drawn square or the device
 * shears, and a UI unit is not the same length across as down. The side is
 * found in pixels and converted with pixelW and pixelH, which is the one way to
 * get the same number of pixels each way.
 *
 * Arguments:
 * 0: Device class in CfgJmfsbDevices <STRING>
 * 1: Fraction of the monitor the device body may fill <NUMBER> (optional, default 1)
 *
 * Return Value:
 * 0: Frame position [x, y, w, h] <ARRAY>
 * 1: Screen position [x, y, w, h] <ARRAY>
 * 2: Frame texture path, "" when the device is unknown <STRING>
 * 3: The screen hole's corner radius [w, h] (the frame's `corner`, scaled) <ARRAY>
 *
 * Example:
 * (["large", 1] call jmfsb_devices_fnc_layout) params ["_framePos", "_screenPos", "_texture"]
 *
 * Public: Yes
 */

params [["_device", "large", [""]], ["_fill", 1, [0]]];

private _cfg = configFile >> "CfgJmfsbDevices" >> _device;
if (!isClass _cfg) exitWith {
    WARNING_1("layout: no device '%1' in CfgJmfsbDevices",_device);
    [[0, 0, 0, 0], [0, 0, 0, 0], ""]
};

(getArray (_cfg >> "body")) params ["_bx", "_by", "_bw", "_bh"];
(getArray (_cfg >> "screen")) params ["_sx", "_sy", "_sw", "_sh"];

// The monitor in pixels, and the canvas side that puts the body exactly on it
// along whichever axis the body meets first.
private _availW = (safeZoneW / pixelW) * (_fill max 0.1);
private _availH = (safeZoneH / pixelH) * (_fill max 0.1);
private _side = (_availW / _bw) min (_availH / _bh);

// ONE SCREEN SIZE FOR THE MATCHED DEVICES (user, 2026-10-21: "two different
// frames but the screen in the center is the same size"). The UAV tablet is
// the large tablet with hand grips. Each device of a SCREEN_MATCH pair is
// fitted by its own body, and every one of them takes the smallest screen
// that gives - so the screens are pixel for pixel the same and the wider
// frame, grips included, still fits the monitor. (Before, the UAV tablet
// was shrunk alone when its grips ran off, and its screen came out smaller.)
private _group = [];
{
    _x params ["_a", "_b"];
    if (_device in _x) then {_group append [_a, _b]};
} forEach SCREEN_MATCH;
if (_group isNotEqualTo []) then {
    private _screenPx = _side * _sw;
    {
        private _mCfg = configFile >> "CfgJmfsbDevices" >> _x;
        if (!isClass _mCfg) then {continue};
        (getArray (_mCfg >> "body")) params ["", "", "_mbw", "_mbh"];
        (getArray (_mCfg >> "screen")) params ["", "", "_msw"];
        _screenPx = _screenPx min (((_availW / _mbw) min (_availH / _mbh)) * _msw);
    } forEach _group;
    _side = _screenPx / _sw;
};
private _cw = _side * pixelW;
private _ch = _side * pixelH;

// The body centred on the monitor; the canvas placed so its body lands there.
private _x0 = safeZoneX + safeZoneW / 2 - (_bx + _bw / 2) * _cw;
private _y0 = safeZoneY + safeZoneH / 2 - (_by + _bh / 2) * _ch;

// The hole's corners are slightly round (tools/gen_devices.py SCREEN_CORNER_R;
// user, 2026-10-23): the shell draws its recess band's corners to match.
private _corner = getNumber (_cfg >> "corner");

[
    [_x0, _y0, _cw, _ch],
    [_x0 + _sx * _cw, _y0 + _sy * _ch, _sw * _cw, _sh * _ch],
    getText (_cfg >> "frame"),
    [_corner * _cw, _corner * _ch]
]
