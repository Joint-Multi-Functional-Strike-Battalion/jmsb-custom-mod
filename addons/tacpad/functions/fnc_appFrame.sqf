#include "script_component.hpp"
/*
 * Author: JMSB
 * The chrome every full-size app is drawn in: a centred panel over the map, an
 * inverted title bar with CLOSE at its right, and an empty body handed back.
 *
 * One copy. Each app used to build its own group, border, ground, header, title
 * and close button, which is three transcriptions of the same forty lines and
 * three places for the frame to drift - two of them were still setting a 1.45
 * font height and painting their border in the divider colour long after the
 * panels had stopped.
 *
 * Only ONE app is open at a time and opening a second replaces the first. The
 * map is underneath and stays the point; a stack of windows over it is a desktop.
 *
 * Arguments:
 * 0: Map display <DISPLAY>
 * 1: Title <STRING>
 * 2: Width in safe-zone fractions - on a device host the app takes the whole host <NUMBER> (optional, default 0.34)
 * 3: Height in safe-zone fractions <NUMBER> (optional, default 0.56)
 * 4: Scrolling body <BOOL> (optional, default false)
 *
 * Return Value:
 * 0: The app's group <CONTROL>
 * 1: The body to fill <CONTROL>
 *
 * Example:
 * ([_display, "SQUAD STATUS", 0.5, 0.6] call jmfsb_tacpad_fnc_appFrame) params ["_group", "_body"]
 *
 * Public: Yes
 */

params [
    ["_display", displayNull, [displayNull]],
    ["_title", "", [""]],
    ["_wf", 0.34, [0]],
    ["_hf", 0.56, [0]],
    ["_scroll", false, [false]]
];

if (isNull _display) exitWith {[controlNull, controlNull]};

private _existing = uiNamespace getVariable [QGVAR(appGroup), controlNull];
if (!isNull _existing) then {ctrlDelete _existing};

([] call FUNC(theme)) params ["_ground", "_ink", "_accent", "_line"];

private _bx = RULE_THICK * pixelW;
private _by = RULE_THICK * pixelH;
private _pad = PAD * HOST_W;
// THE BAND IS AS TALL AS ITS TEXT LINE, so the body starts BELOW the whole
// CLOSE hit. The band was the constant alone while the CLOSE hit (created
// after the body, on top of it - see below) was sized `_headerH max _lineH`:
// past the text size where the line outgrows the constant, the hit spilled
// into the body's first row - the app's tab row - by the difference. A press
// that started on that spill and released a few pixels lower fired neither
// the close nor the tab: "the my record button is hard to click / nothing
// happens" (user, 2026-09-05). FUNC(appIdle) already sizes the band this way.
private _headerH = (HEADER_H * GVAR(textScale) * GVAR(uiScale) * HOST_H) max ([TEXT_TITLE] call FUNC(textH));

// CLAMPED TO THE SCREEN. An app that asks for more height than there is gets
// centred at a NEGATIVE y - the frame runs off the top and the bottom at once,
// and the last rows are somewhere the player cannot reach. That is what "I have
// to scroll to see it all" means on a screen with no scrollbar: nothing was
// scrolling, the content was simply off the display.
//
// A measured app that overflows is an app whose layout is wrong, and clamping
// does not fix that - but it makes the failure visible as clipping at the bottom
// edge instead of hiding half the page beyond both edges.
if (HOST_DEVICE) then {
    _wf = APP_DEVICE_FILL;
    _hf = APP_DEVICE_FILL;
};
private _w = (_wf min 1) * HOST_W;
private _h = (_hf min 1) * HOST_H;

private _group = _display ctrlCreate [QGVAR(panel), -1];
_group setVariable [QGVAR(owned), true];   // see FUNC(build)
_group ctrlSetPosition [HOST_X + (HOST_W - _w) / 2, HOST_Y + (HOST_H - _h) / 2, _w, _h];
_group ctrlCommit 0;
uiNamespace setVariable [QGVAR(appGroup), _group];

private _fill = _display ctrlCreate [QGVAR(fill), -1, _group];
_fill ctrlSetPosition [0, 0, _w, _h];
_fill ctrlSetBackgroundColor _ground;
_fill ctrlCommit 0;

// THE BOTTOM NET. The ground is the LOWEST control in the window - a press
// only reaches it when nothing above wanted it. A press in the title-bar
// band that got this far means the close chain above failed somehow, and
// after four rounds of "intrusion will not close" the ground stops relaying
// that failure and closes the app itself. Both coordinate readings are
// tested because the engine's control-event space is the one thing this
// window cannot see from inside.
_fill setVariable [QGVAR(headerBand), (HEADER_H * GVAR(textScale) * GVAR(uiScale) * HOST_H) max ([TEXT_TITLE] call FUNC(textH))];
_fill ctrlAddEventHandler ["MouseButtonDown", {
    params ["_ctrl", "_button", "", "_my"];
    if (_button isNotEqualTo 0) exitWith {true};

    private _band = _ctrl getVariable [QGVAR(headerBand), 0];
    (ctrlPosition (ctrlParentControlsGroup _ctrl)) params ["", "_gy"];

    if (_my <= _band || {_my >= _gy && {_my <= _gy + _band}}) then {
        [] call FUNC(appClose);
    };
    true
}];

[_group, [0, 0, _w, _h], _ink, RULE_THICK] call FUNC(drawFrame);

private _header = _display ctrlCreate [QGVAR(fill), -1, _group];
_header ctrlSetPosition [_bx, _by, _w - 2 * _bx, _headerH];
_header ctrlSetBackgroundColor _ink;
_header ctrlCommit 0;

[_group, [_bx + _pad, _by, (_w - 2 * _bx) * 0.7, _headerH], _title, _ground, TEXT_TITLE, true] call FUNC(drawText);
[_group, [_bx + (_w - 2 * _bx) * 0.7, _by, (_w - 2 * _bx) * 0.3 - _pad, _headerH], "CLOSE", _ground, TEXT_TITLE, true, "right"] call FUNC(drawText);

// NO SCROLLBAR BY DEFAULT. An app that knows how many rows it has should be the
// size of them - a bar down the side of a screen that could have been an inch
// taller is the app admitting it did not measure itself. Ask for one only when
// the content genuinely cannot be bounded.
private _body = _display ctrlCreate [([QGVAR(panel), QGVAR(body)] select _scroll), -1, _group];
_body ctrlSetPosition [_bx, _by + _headerH, _w - 2 * _bx, _h - 2 * _by - _headerH];
_body ctrlSetBackgroundColor [0, 0, 0, 0];
_body ctrlCommit 0;

// CLOSE IS CREATED LAST, AFTER THE BODY, and that is the whole point of where it
// sits in this file. It was created before the body - and the body is a CONTROLS
// GROUP, which takes the mouse over its entire rectangle. One pixel of overlap
// between the two, at any text size or UI scale, and the group has the press and
// the close button never sees it. That is "the window will not close", and it
// was reported on two different screens because it was never about either of
// them.
//
// Nothing an app draws can cover it either: an app fills the BODY, so its
// controls are children of a group that is now underneath this one.
//
// AND IT SPANS THE LABELS' REAL HEIGHT. drawText gives a line max(line, box)
// of height, so past the text size where the line outgrows the header bar the
// CLOSE label stood taller than this hit - and a label not WHOLLY inside the
// hit is a label drawHit will not claim, which is a CLOSE that eats its own
// presses. That is "could not close the window", and it only appeared at the
// text sizes the header was never tested at.
private _lineH = [TEXT_TITLE] call FUNC(textH);
private _closeHit = [_group, [_bx, _by, _w - 2 * _bx, _headerH max _lineH], {
    // ONE TEARDOWN for every way out - see FUNC(appClose).
    [] call FUNC(appClose);
}] call FUNC(drawHit);

// AND CLOSE FIRES ON THE PRESS, NOT THE CLICK. A ButtonClick is a down AND a
// release on the SAME control - and this hit is the topmost thing in the
// header, so it takes every down that lands there, including the ones whose
// release it never sees because a refresh loop rebuilt the window in
// between. That press died silently: the button was deleted holding it, the
// labels and the bottom net underneath never saw it, and the window "would
// not close" - on every app with a live loop, however many nets were laid
// UNDER a control that eats from ABOVE. The down cannot be raced: whatever
// control receives it acts on it, that frame. ButtonClick stays as the
// second barrel; the handler is idempotent, so both firing costs nothing.
_closeHit ctrlAddEventHandler ["MouseButtonDown", {
    params ["_ctrl", "_button"];
    if (_button isNotEqualTo 0) exitWith {false};
    [_ctrl] call (_ctrl getVariable [QGVAR(hitHandler), {}]);
    true
}];

[_group, _body]
