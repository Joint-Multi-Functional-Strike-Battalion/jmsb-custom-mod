#include "script_component.hpp"
/*
 * Author: JMSB
 * Opens an app full size over the map. This is what a live tile does when it is
 * clicked, and it is the only route in - a tile never opens anything itself, so
 * there is one place that knows how an app is shown.
 *
 * An app that is not loaded is a no-op rather than an error. The suite is meant
 * to be assembled from whatever addons a mission has, and a tile for a missing
 * app should sit there inert, not throw.
 *
 * Arguments:
 * 0: App id, matching a registered app <STRING>
 * 1: Arguments passed to the app <ANY> (optional, default [])
 * 2: A human asked for this, not a screen that was open a moment ago <BOOL>
 *    (optional, default false). A reopen - a refresh loop's direct call, a
 *    press inside the app that queued one for next frame - belongs to the
 *    window that scheduled it, and the moment that window is gone the reopen
 *    is a jmfsb. The panels and tiles are the only humans; they pass true.
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["squad"] call jmfsb_tacpad_fnc_openApp
 *
 * Public: Yes
 */

params [["_app", "", [""]], ["_args", []], ["_fresh", false, [false]]];

if (!hasInterface || _app == "") exitWith {false};

private _handler = GVAR(appHandlers) getOrDefault [_app, {}];
if (_handler isEqualTo {}) exitWith {
    INFO_1("no app registered as '%1' - tile press ignored",_app);
    false
};

private _display = HOST_DISPLAY;
if (isNull _display) exitWith {false};

// A STALE REOPEN IS REFUSED BEFORE IT TOUCHES ANYTHING. Every redraw in the
// suite reopens the app - a live app reopens itself on a timer, a press inside
// the app queues a reopen for next frame - and the only thing that says a
// reopen is still wanted is the window it came from still being the open one.
// A close fires on the press, so the sequence "press a row, close the window"
// had its reopen land AFTER the close and the window came straight back: "I
// closed it and it opened again" is a stuck window wearing a different coat.
// The guard refuses any reopen whose app is no longer current - and a human
// asking for a different app is the one caller allowed to change it.
if ((uiNamespace getVariable [QGVAR(appCurrent), ""]) isNotEqualTo _app && {!_fresh}) exitWith {
    private _current = uiNamespace getVariable [QGVAR(appCurrent), ""];
    INFO_2("stale reopen of '%1' refused - the open app is '%2'",_app,_current);
    false
};

// THE APP IT REPLACES HEARS THAT IT HAS GONE. Its group is deleted by
// FUNC(appFrame) below; a screen that keeps state of its own off the group -
// the reader's display, inside the tablet - drops it on this event.
private _was = uiNamespace getVariable [QGVAR(appCurrent), ""];
if (_was isNotEqualTo "" && _was isNotEqualTo _app) then {
    [QGVAR(appClosed), [_was]] call CBA_fnc_localEvent;
};

// WHICH APP IS OPEN, WRITTEN DOWN BEFORE IT OPENS. A live app refreshes itself
// by reopening on a timer, and it decides whether to keep doing that by asking
// whether an app group exists - which is true of ANY app, including the one that
// replaced it. So opening SETTINGS after HACK left the hack's loop running: it
// tore the settings screen down and rebuilt the hack's every second, under the
// player's cursor, and a control deleted between the press and the release never
// raises a click. That is the whole of "the window would not click and would not
// close". A loop compares this against its own id now.
uiNamespace setVariable [QGVAR(appCurrent), _app];

// WHEN THE SCREEN WAS LAST ACTUALLY DRAWN. FUNC(appIdle) holds a redraw while
// the cursor is on the app so a press cannot be deleted mid-click, and without
// this stamp that hold has no end - a player watching a progress bar leaves the
// cursor there and the screen freezes on its first frame.
uiNamespace setVariable [QGVAR(appDrawn), diag_tickTime];

// The originating tile stays visible in the app's header as the way back, so
// the app is told which one sent it.
//
// AND A DRAW THAT THROWS MUST NOT TAKE THE LAYER WITH IT. A handler dying
// halfway - bad data, a race, a config gone missing - otherwise aborts this
// function at the call, before the panels hide and the bar draws, leaving
// appCurrent set to an app nobody can see and no way out of it. Catch it,
// log it, and carry on with the bookkeeping: a broken window still has to
// close. The throw's own partial screen stays up under the bar, closeable.
try {
    [_display, _app, _args] call _handler;
} catch {
    ERROR_2("openApp '%1' threw: %2",_app,_exception);
};

// AN OPEN APP IS MODAL: the panels HIDE under it. A panel that rebuilds
// while an app is open is created ABOVE it - and its ground eats every
// press, which on a wide app is exactly where CLOSE stands. "The intrusion
// page will not close", three reports running, was the reader panel lying
// over the CLOSE button. FUNC(appFrame)'s close shows them again.
{
    (_x param [0, controlNull]) ctrlShow false;
} forEach values (missionNamespace getVariable [QGVAR(open), createHashMap]);

// TWO WAYS OUT, HUNG ON THE DISPLAY ITSELF - the user's call: no panic
// button, a page closes the way every other window in the game closes. ESC
// and a press on the map, once per display - see FUNC(appExits), which a
// self-drawn screen adopted with FUNC(appHost) shares.
[_display] call FUNC(appExits);

[QGVAR(appOpened), [_app, _args]] call CBA_fnc_localEvent;

true
