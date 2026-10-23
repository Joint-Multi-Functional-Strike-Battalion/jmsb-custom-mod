#include "script_component.hpp"
/*
 * Author: JMSB
 * Makes a screen that draws itself the open app on the host. FUNC(openApp) is
 * for an app with a handler that builds into FUNC(appFrame); this is for one
 * that already has its own group on the host display and only needs to BE the
 * open app - the TAC//MSG reader and TAC//PAC, which inside the tablet are drawn
 * on the device dialog instead of opening a dialog over it (user, 2026-10-20:
 * "all apps need to be inside the tablet").
 *
 * Everything an open app gets, it gets: the panels hide under it, ESC and a
 * press on the map close it (FUNC(appExits)), FUNC(appClose) deletes its group,
 * a tile or soft key opening another app replaces it, and every way it stops
 * being open raises QGVAR(appClosed) with its id.
 *
 * THE APP IT REPLACES GOES NEXT FRAME. This is reached from presses inside
 * other apps - COMPOSE in the comms app opens the reader - and deleting the
 * group that holds the running handler is how a press takes its own button
 * with it. The old group is hidden now and deleted a frame later.
 *
 * Arguments:
 * 0: App id <STRING>
 * 1: The screen's group, already on the host display <CONTROL>
 *
 * Return Value:
 * Adopted <BOOL>
 *
 * Example:
 * [READER_APP, _root] call jmfsb_tacpad_fnc_appHost
 *
 * Public: Yes
 */

params [["_app", "", [""]], ["_group", controlNull, [controlNull]]];

if (!hasInterface || _app isEqualTo "" || isNull _group) exitWith {false};

private _display = HOST_DISPLAY;
if (isNull _display || {(ctrlParent _group) isNotEqualTo _display}) exitWith {false};

private _old = uiNamespace getVariable [QGVAR(appGroup), controlNull];
if (!isNull _old && _old isNotEqualTo _group) then {
    _old ctrlShow false;
    [{
        params ["_old"];
        if (!isNull _old) then {ctrlDelete _old};
    }, [_old]] call CBA_fnc_execNextFrame;
};

private _was = uiNamespace getVariable [QGVAR(appCurrent), ""];
if (_was isNotEqualTo "" && _was isNotEqualTo _app) then {
    [QGVAR(appClosed), [_was]] call CBA_fnc_localEvent;
};

uiNamespace setVariable [QGVAR(appCurrent), _app];
uiNamespace setVariable [QGVAR(appGroup), _group];
uiNamespace setVariable [QGVAR(appDrawn), diag_tickTime];
uiNamespace setVariable [QGVAR(appMapClaim), ""];

// Modal, as FUNC(openApp) has it: a panel left showing would be stacked over
// the screen the next time it rebuilt, and its ground would eat the presses.
{
    (_x param [0, controlNull]) ctrlShow false;
} forEach values (missionNamespace getVariable [QGVAR(open), createHashMap]);

[_display] call FUNC(appExits);

[QGVAR(appOpened), [_app, []]] call CBA_fnc_localEvent;

true
