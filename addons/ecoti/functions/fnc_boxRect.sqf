#include "script_component.hpp"
/*
 * Author: JMSB
 * Where a target's box goes on screen: round the given points, square to the
 * screen, as a UI rectangle snapped to whole pixels - so FUNC(drawBoxes) lays
 * its four sides edge to edge and the corners meet (user, 2026-10-17: "4
 * lines that do not line up").
 *
 * The box is the points' extent along the camera's right and up about their
 * centre, plus a margin. It is given whole inside the thermal window or not at
 * all.
 *
 * Arguments:
 * 0: Points, AGL <ARRAY>
 * 1: Margin, metres <NUMBER>
 * 2: View - [camPos, camFwd, camRight, camUp, window] <ARRAY>
 *
 * Return Value:
 * [left, top, width, height] in UI units, or [] when it is not to be drawn <ARRAY>
 *
 * Example:
 * [[_feet, _crown], 0.25, _view] call jmfsb_ecoti_fnc_boxRect
 *
 * Public: No
 */

params ["_points", "_margin", "_view"];
_view params ["", "", "_camRight", "_camUp", "_window"];

private _centre = ORIGIN;
{
    _centre = _centre vectorAdd _x;
} forEach _points;
_centre = _centre vectorMultiply (1 / count _points);

private _halfW = 0;
private _halfH = 0;
{
    private _offset = _x vectorDiff _centre;
    _halfW = _halfW max (abs (_offset vectorDotProduct _camRight));
    _halfH = _halfH max (abs (_offset vectorDotProduct _camUp));
} forEach _points;

private _screenCentre = worldToScreen _centre;
private _screenRight = worldToScreen (_centre vectorAdd (_camRight vectorMultiply (_halfW + _margin)));
private _screenUp = worldToScreen (_centre vectorAdd (_camUp vectorMultiply (_halfH + _margin)));
if ([_screenCentre, _screenRight, _screenUp] findIf {_x isEqualTo []} >= 0) exitWith {[]};

// The window test, in screen heights from the centre: the far corner inside it.
private _flat = SCREEN_XY(_screenCentre);
private _w = (SCREEN_XY(_screenRight)) distance _flat;
private _h = (SCREEN_XY(_screenUp)) distance _flat;
_flat params ["_cx", "_cy"];
if (sqrt (((abs _cx) + _w) ^ 2 + ((abs _cy) + _h) ^ 2) > _window) exitWith {[]};

// Back to UI units - x narrowed again as SCREEN_XY widened it - and onto the pixel grid.
private _halfUiW = _w * safeZoneH / ASPECT_4_3;
private _halfUiH = _h * safeZoneH;
_screenCentre params ["_sx", "_sy"];
private _left = PIXEL_X(_sx - _halfUiW);
private _top = PIXEL_Y(_sy - _halfUiH);

[_left, _top, (PIXEL_X(_sx + _halfUiW)) - _left, (PIXEL_Y(_sy + _halfUiH)) - _top]
