#include "script_component.hpp"
/*
 * Author: YonV
 * The call's picture as a window floating over the screen (user, 2026-10-28:
 * "on tablet and phone have it over top"): the other man on the player's live
 * call, his face or his view, whichever he sends
 * (jmfsb_tacpad_apps_fnc_callFeed), in a corner of the map area, with who it
 * is and which along its foot. Nothing is drawn, and the old window goes,
 * while there is no live call.
 *
 * BUILT ONCE, KEPT (code review R8). The ground, the picture and the caption
 * are made when the call shows and kept: a new caption is written into the
 * caption in place, and the render-to-texture picture is never made again on
 * a tick - remaking it every half second was a flicker. The three are made
 * again only when their change key differs (the corner, the size, the fade,
 * the scheme) or when they are no longer on top.
 *
 * IT STAYS ON TOP. Arma cannot raise a control, so a window something was
 * built over since - an app, a panel - is made again, newest. "On top" is the
 * caption being the display's last top-level control; whatever is drawn
 * inside a group made before the window stays under it. It has no buttons,
 * so remaking it loses no press, and a second call in the same frame finds it
 * on top with the same key and does nothing.
 *
 * Arguments:
 * 0: Display to draw on <DISPLAY>
 * 1: Map area [x, y, w, h] <ARRAY>
 * 2: Corner, 0 top left, 1 top right, 2 bottom right, 3 bottom left <NUMBER>
 * 3: Width as a share of the map area <NUMBER>
 * 4: Hint on the caption's right, "" for none <STRING>
 * 5: Fade, 0 opaque <NUMBER>
 * 6: Alive test for the feed - true while this screen is up <CODE>
 *
 * Return Value:
 * Drawn <BOOL>
 *
 * Example:
 * [_display, _map, 3, 0.3, "0 / . MOVE", 0, {true}] call jmfsb_devices_fnc_callWindow
 *
 * Public: No
 */

params [
    ["_display", displayNull, [displayNull]],
    ["_area", [0, 0, 0, 0], [[]], 4],
    ["_corner", CALL_CORNER_DEFAULT, [0]],
    ["_share", CALL_WINDOW_SHARE, [0]],
    ["_hint", "", [""]],
    ["_fade", 0, [0]],
    ["_alive", {false}, [{}]]
];

if (isNull _display) exitWith {false};

private _made = _display getVariable [QGVAR(callCtrls), []];
private _shown = [];
if (!isNil QEFUNC(tacpad_apps,callFeedUnit)) then {
    _shown = [] call EFUNC(tacpad_apps,callFeedUnit);
};
if (_shown isEqualTo []) exitWith {
    {ctrlDelete _x} forEach _made;
    _display setVariable [QGVAR(callCtrls), []];
    false
};

// The corner: left or right, top or bottom of the map area, a gap in.
_area params ["_ax", "_ay", "_aw", "_ah"];
private _w = _aw * _share;
private _h = (_w / pixelW) * CALL_WINDOW_ASPECT * pixelH;
private _gx = CALL_WINDOW_GAP_PX * pixelW;
private _gy = CALL_WINDOW_GAP_PX * pixelH;
private _x0 = [_ax + _gx, _ax + _aw - _w - _gx] select (_corner in [1, 2]);
private _y0 = [_ay + _gy, _ay + _ah - _h - _gy] select (_corner in [2, 3]);

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink"];
private _capH = _h * CALL_WINDOW_CAPTION;
private _picH = _h - _capH;

// Made again only on a new key, when one of the three has gone, or when
// something top-level was built after it.
private _fresh = [_display, QGVAR(callWindow), [_x0, _y0, _w, _h, _fade, _ground, _ink]] call EFUNC(tacpad,changed);
private _whole = (count _made) isEqualTo CALL_WINDOW_PARTS && {(_made findIf {isNull _x}) < 0};
private _onTop = _whole && {
    private _top = (allControls _display) select {isNull (ctrlParentControlsGroup _x)};
    (_top select -1) isEqualTo (_made select -1)
};

if (_fresh || {!_onTop}) then {
    {ctrlDelete _x} forEach _made;
    _made = [];

    private _solid = [_ink # 0, _ink # 1, _ink # 2, 1];
    private _fnc_make = {
        params ["_class", "_rect"];
        private _c = _display ctrlCreate [_class, -1];
        _c ctrlSetPosition _rect;
        _c ctrlSetFade _fade;
        _made pushBack _c;
        _c
    };

    private _back = ["RscText", [_x0, _y0, _w, _h]] call _fnc_make;
    _back ctrlSetText "";
    _back ctrlSetBackgroundColor _solid;
    _back ctrlCommit 0;

    private _picture = ["RscPicture", [_x0, _y0, _w, _picH]] call _fnc_make;
    _picture ctrlSetText format ["#(argb,%1,%1,1)r2t(%2,%3)", CALL_FEED_RES, CALL_FEED_RTT, (_w / pixelW) / (_picH / pixelH)];
    _picture ctrlCommit 0;

    private _caption = ["RscStructuredText", [_x0, _y0 + _picH, _w, _capH]] call _fnc_make;
    _caption ctrlSetBackgroundColor [0, 0, 0, 0];
    _caption ctrlSetFontHeight (_capH * CALL_WINDOW_CAPTION_FONT);
    _caption ctrlCommit 0;

    _display setVariable [QGVAR(callCtrls), _made];
};

// Who it is and which, written into the caption only when it changes.
private _caption = _made select -1;
private _markup = format [
    "<t font='RobotoCondensedBold' color='%1' shadow='0'>%2</t><t align='right' font='RobotoCondensed' color='%1' shadow='0'>%3</t>",
    _ground call BIS_fnc_colorRGBAtoHTML, [_shown select 2] call EFUNC(tacpad,xmlSafe), [_hint] call EFUNC(tacpad,xmlSafe)
];
if (_markup isNotEqualTo (_caption getVariable [QGVAR(callCaption), ""])) then {
    _caption setVariable [QGVAR(callCaption), _markup];
    _caption ctrlSetStructuredText parseText _markup;
};

["show", _alive] call EFUNC(tacpad_apps,callFeed);
true
