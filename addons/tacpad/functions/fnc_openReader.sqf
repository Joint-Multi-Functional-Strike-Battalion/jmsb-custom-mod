#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens the full-size TAC//MSG reader - the design's option 1a, three panes:
 * nets and roster down the left, the traffic list beside it, the opened thread
 * filling the rest.
 *
 * IT IS A SHELL AND A REDRAW. This creates the root group and, in a dialog,
 * the display; FUNC(readerDraw) puts everything else on it and is called again
 * whenever the selection changes. Nothing here knows what a thread looks like.
 *
 * INSIDE THE TABLET IT IS NOT A DIALOG (user, 2026-10-20: "tac//msg needs to be
 * inside the tablet"). With the device open as the host, the root is created on
 * the device dialog in the tablet's map area and adopted as the open app
 * (FUNC(appHost), id READER_APP) - so the tiles, the device bar and the net row
 * stay round it, ESC and CLOSE take it down and leave the tablet up, and a tile
 * replaces it like any other app. Every pane of TAC//MSG - the rail, the list
 * and its filter, the thread, the net view, the composer, the template and
 * recipient pickers, the report card, the quick replies - is drawn into this
 * root, so all of it is inside. The edits are ctrlCreate'd into the device
 * dialog, which is a dialog and takes keyboard focus.
 *
 * GVAR(reader) is the display the reader is on either way - the reader dialog,
 * or the device dialog while the root is up there; it is cleared when the app
 * closes (the QGVAR(appClosed) handler in XEH_postInit).
 *
 * On the vanilla map, and in tablet mode with no device open (the keybind out
 * in the world), it is the dialog it always was.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_openReader
 *
 * Public: Yes
 */

if (!hasInterface) exitWith {false};

if (isNil QEGVAR(messaging,index)) exitWith {
    ["READER", "Messaging is not loaded.", "high"] call EFUNC(messaging,notify);
    false
};

private _inHost = HOST_DEVICE && {!isNull (HOST_DISPLAY)};
private _display = displayNull;

if (_inHost) then {
    _display = HOST_DISPLAY;
    // One reader. A second root under the same idc would leave every
    // displayCtrl in the reader answering with whichever the engine likes.
    private _old = _display displayCtrl IDC_RD_ROOT;
    if (!isNull _old) then {ctrlDelete _old};
    uiNamespace setVariable [QGVAR(reader), _display];
} else {
    if (createDialog QGVAR(reader)) then {
        _display = uiNamespace getVariable [QGVAR(reader), displayNull];
    };
};
if (isNull _display) exitWith {false};

([] call FUNC(theme)) params ["_ground", "_ink"];

// The screen, as one group. Everything drawn on it is a child, so a redraw is
// "delete this group's children" rather than a hunt through the display.
// Wider, and the extra belongs to the compose side - asked for in red. Inside
// a device it takes the whole map area like every other app (APP_DEVICE_FILL;
// user, 2026-10-21: TAC//MSG "filling the space like the other apps").
private _w = ([READER_FILL_W, APP_DEVICE_FILL] select _inHost) * HOST_W;
private _h = ([READER_FILL_H, APP_DEVICE_FILL] select _inHost) * HOST_H;

private _root = _display ctrlCreate [QGVAR(panel), IDC_RD_ROOT];
_root ctrlSetPosition [HOST_X + (HOST_W - _w) / 2, HOST_Y + (HOST_H - _h) / 2, _w, _h];
_root ctrlCommit 0;

// SOLID INSIDE THE TABLET. The dialog has a backdrop dimming the world behind
// it; on the device the map is directly underneath, and a see-through ground
// would put the map's labels through the traffic.
private _fill = _display ctrlCreate [QGVAR(fill), -1, _root];
_fill ctrlSetPosition [0, 0, _w, _h];
_fill ctrlSetBackgroundColor ([_ground, [_ground # 0, _ground # 1, _ground # 2, 1]] select _inHost);
_fill ctrlCommit 0;
_fill ctrlAddEventHandler ["MouseButtonDown", {true}];

[_root, [0, 0, _w, _h], _ink, RULE_THICK] call FUNC(drawFrame);

if (_inHost) then {
    // The open app: panels hidden under it, ESC and a map press close it - see
    // FUNC(appExits) - and the tablet stays up.
    [READER_APP, _root] call FUNC(appHost);
} else {
    // ESC closes it, which is what every other full-screen thing in the game does.
    _display displayAddEventHandler ["KeyDown", {
        params ["_d", "_key"];
        if (_key == KEY_ESCAPE) exitWith {_d closeDisplay 0; true};
        false
    }];
};

GVAR(readerThread) = "";
GVAR(readerTab) = "all";
GVAR(readerFilter) = "";
GVAR(readerMarkers) = false;

// A reader opened cold is never mid-message. FUNC(composeOpen) turns compose
// back on after this returns, which is why the order matters.
GVAR(composeOn) = false;
GVAR(composePick) = false;
GVAR(composeToPick) = false;
GVAR(composeMarker) = "";
GVAR(composePin) = [];
GVAR(composePinPick) = false;
GVAR(composeValues) = createHashMap;
GVAR(composeGridText) = createHashMap;
GVAR(composeTemplate) = "";
GVAR(composeThread) = "";
GVAR(composeTo) = "";
GVAR(composeCc) = "";
GVAR(composeTags) = "";
GVAR(composeError) = "";
GVAR(composeMissing) = [];

[] call FUNC(readerDraw);

true
