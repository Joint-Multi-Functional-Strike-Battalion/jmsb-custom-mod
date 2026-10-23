#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet dialog has opened. Dresses it in the frame FUNC(open) chose, sizes
 * the map to the screen, hands the dialog to the shell as its host and has the
 * shell build the suite into it.
 *
 * THE TABLET SCREEN (docs/DESIGN_TABLET.md). The large, UAV and vehicle
 * tablets - the only frames this dialog wears (FUNC(open)) - cut the screen
 * into rows (FUNC(tabletRows)): the device bar, the notification line and the
 * live tiles above the map, the net row under it. The map - and with it the
 * shell's host - is only the map area between them, and the panels go to the
 * tablet's fixed places there instead of their safe-zone defaults.
 *
 * Called by the dialog's own onLoad, so by the time it runs every declared
 * control exists and nothing created at runtime does - which is the order the
 * shell needs: its groups are created over the map and the frame, never under.
 *
 * Arguments:
 * 0: The dialog's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};

uiNamespace setVariable [QGVAR(display), _display];

([GVAR(device), GVAR(tabletFill)] call FUNC(layout)) params ["_framePos", "_screenPos", "_texture", "_corner"];

private _frame = _display displayCtrl IDC_TABLET_FRAME;
_frame ctrlSetText _texture;
_frame ctrlSetPosition _framePos;
_frame ctrlCommit 0;

// The keys printed on the frame become mouse buttons over the art.
[_display, GVAR(device), _framePos] call FUNC(keyButtons);

// The rows round the map, the map area the suite is hosted in, and the fixed
// places its panels take there.
private _rows = [_screenPos, _corner] call FUNC(tabletRows);
_display setVariable [QGVAR(rows), _rows];
private _host = _rows get "map";
private _places = createHashMapFromArray ([TABLET_PLACES, TABLET_PLACES_VEHICLE] select (GVAR(device) isEqualTo VEHICLE_DEVICE));

// The screen is the map, opened on the player and close in, the way a device
// in the hand would be. No animation: it is already there when the dialog is.
// ctrlMapSetPosition, not ctrlSetPosition: the control is declared 0 x 0 and a
// map moved with ctrlSetPosition keeps its declared viewport, so a centre put
// on it lands off the middle of the screen (FUNC(overlayPlace)).
private _map = _display displayCtrl IDC_TABLET_MAP;
_map ctrlMapSetPosition _host;
_map ctrlMapAnimAdd [0, MAP_SCALE_OPEN, getPos (call CBA_fnc_currentUnit)];
ctrlMapAnimCommit _map;

// VEHICLE STATUS IS THE VEHICLE TABLET'S. Registered with the shell for as
// long as this dialog wears the vehicle frame, and out of the registry on any
// other frame - so the arrows' ring, the F-keys and the tile band only ever
// find it here. FUNC(onUnload) takes it out again.
if (GVAR(device) isEqualTo VEHICLE_DEVICE) then {
    [VEHICLE_APP, FUNC(appVehicle)] call EFUNC(tacpad,registerApp);
} else {
    EGVAR(tacpad,appHandlers) deleteAt VEHICLE_APP;
};

// The keyboard's LEFT / RIGHT. Added before the shell wires its own ESC
// handler, and returning false for anything that is not ours, so both run.
_display displayAddEventHandler ["KeyDown", {_this call FUNC(keyDown)}];

// THE HANDOVER. The shell draws wherever its host says; from here until
// FUNC(onUnload) that is this dialog and this rectangle, with this layout.
// NO APP IS OPEN ON A DIALOG THAT JUST OPENED. appCurrent lives in uiNamespace
// and outlives a mission; a stale one makes every panel build hidden.
uiNamespace setVariable [QEGVAR(tacpad,appCurrent), ""];
[_host, _display, _places] call EFUNC(tacpad,setHost);

// BUILT ONE FRAME LATER, NOT INSIDE onLoad. The first tablet (user screenshot,
// 2026-10-19) showed the map in its frame and none of the eight panels the log
// said were built on it. A control created while the display's own onLoad is
// still running is the one thing this host does that the vanilla map never
// does, so the suite now goes up on the next frame, when the dialog is live;
// the frame below logs where every panel landed and whether it is shown, so
// the next report carries numbers instead of a screenshot.
[{
    params ["_display", "_screenPos"];
    if (isNull _display) exitWith {};
    [_display] call FUNC(tabletChrome);
    [] call EFUNC(tacpad,open);
    // The right-hand column under its panels' real bottoms at once, not half a
    // second later on the row tick.
    [] call FUNC(tabletStack);
    INFO_3("tablet open: screen %1, host %2, %3 controls on the dialog",_screenPos,EGVAR(tacpad,host),count allControls _display);
    [{
        params ["_display"];
        if (isNull _display) exitWith {};
        {
            _y params [["_group", controlNull], ["_body", controlNull]];
            INFO_5("panel %1: group %2 shown %3, body shown %4, %5 controls in it",_x,ctrlPosition _group apply {round (_x * 1000) / 1000},ctrlShown _group,ctrlShown _body,count allControls _group);
        } forEach EGVAR(tacpad,open);
        private _map = _display displayCtrl IDC_TABLET_MAP;
        private _frame = _display displayCtrl IDC_TABLET_FRAME;
        INFO_2("map at %1, frame at %2",ctrlPosition _map apply {round (_x * 1000) / 1000},ctrlPosition _frame apply {round (_x * 1000) / 1000});
    }, [_display]] call CBA_fnc_execNextFrame;
}, [_display, _screenPos]] call CBA_fnc_execNextFrame;
