#include "script_component.hpp"
/*
 * Author: JMSB
 * Fits one of this addon's dialogs - the console, the message box, TIME /
 * WEATHER - to the tablet's screen when the tacpad is hosted on a device that
 * is open, instead of the whole monitor (user, 2026-10-20: "all apps need to
 * be inside the tablet").
 *
 * PLACED ON THE SCREEN, NOT DRAWN INTO IT. The console is two hundred declared
 * controls driven by idc from sixty-odd ported functions, a live map and a PiP
 * camera; rebuilding that inside the device dialog would be a second console.
 * So it stays its own dialog and is laid over the tablet's map area exactly -
 * every control's safe-zone rectangle mapped onto the host rectangle the tacpad
 * draws in (jmfsb_tacpad_host), with the type scaled by the smaller of the two
 * ratios - which leaves the device bar, the tiles and the net row of the
 * tablet visible round it. ESC closes it back to the tablet.
 *
 * Every control in these dialogs is set to the same base type height and
 * varies by inline <t size>, as FUNC(style) relies on, so one base serves.
 *
 * Arguments:
 * 0: The dialog <DISPLAY>
 *
 * Return Value:
 * Fitted - false where there is no open device to fit to <BOOL>
 *
 * Example:
 * [_display] call jmfsb_adminpanel_fnc_fitHost
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {false};
if (HOST_NATIVE || {isNull (HOST_DISPLAY)}) exitWith {false};

private _sx = HOST_W / safeZoneW;
private _sy = HOST_H / safeZoneH;
private _font = ADMIN_FONT_BASE * HOST_K;

{
    (ctrlPosition _x) params ["_x0", "_y0", "_w0", "_h0"];
    // A child of a controls group is placed relative to its group, which
    // moves with it; only its size changes.
    private _rect = if (isNull (ctrlParentControlsGroup _x)) then {
        [HOST_X + (_x0 - safeZoneX) * _sx, HOST_Y + (_y0 - safeZoneY) * _sy, _w0 * _sx, _h0 * _sy]
    } else {
        [_x0 * _sx, _y0 * _sy, _w0 * _sx, _h0 * _sy]
    };
    // THE CAMERA PICTURE KEEPS ITS SHAPE (user, 2026-10-21: "fix the ratio").
    // The fit stretches width and height apart; a render-to-texture view
    // (PLAYER VIEW's r2t) takes the smaller of the two, centred in its slot.
    if (((ctrlText _x) find RENDER_TARGET_TAG) >= 0) then {
        private _k = _sx min _sy;
        _rect params ["_rx", "_ry", "_rw", "_rh"];
        _rect = [_rx + (_rw - _w0 * _k) / 2, _ry + (_rh - _h0 * _k) / 2, _w0 * _k, _h0 * _k];
    };
    _x ctrlSetPosition _rect;
    _x ctrlSetFontHeight _font;
    _x ctrlCommit 0;
} forEach (allControls _display);

true
