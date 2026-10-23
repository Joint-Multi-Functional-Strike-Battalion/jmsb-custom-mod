#include "script_component.hpp"
/*
 * Author: JMSB
 * DRONES, the board (docs/DESIGN_TABLET_APPS.md, DRONES).
 *
 *   FLEET  FLEET (left): the players' side's drones - link, quality, battery
 *          and task - and the enemy drones heard. FEED (right): the picked
 *          drone's camera, live, inside the app, with its HUD, and the
 *          control buttons under it.
 *   ENEMY  what is unmanned and hostile in the air - the intrusion suite's
 *          receiver sweep (EFUNC(hacking,scannerRead)), the same reading the
 *          tile and the handset show.
 *
 * Fleet rows: FUNC(appDronesData). The picture: FUNC(appDronesCamera), which
 * also cleans the camera up when the app closes. Buttons: FUNC(appDronesAction).
 * Drawn inside the tablet and on the vanilla map alike (EFUNC(tacpad,appFrame)).
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["drones", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([_display, "DRONES", PAGE_W, PAGE_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _fleet = [] call FUNC(appDronesData);

// THE PICK: the drone the feed shows. The one linked to the player when
// nothing is picked, else the first; a pick that has gone falls back the same way.
private _pick = uiNamespace getVariable [QGVAR(dronesPick), objNull];
if ((_fleet findIf {(_x select 0) isEqualTo _pick}) < 0) then {
    private _i = _fleet findIf {_x select 6};
    _pick = if (_i >= 0) then {(_fleet select _i) select 0} else {(_fleet param [0, [objNull]]) select 0};
    uiNamespace setVariable [QGVAR(dronesPick), _pick];
};

private _tab = uiNamespace getVariable [QGVAR(dronesTab), "fleet"];
if ((DRONES_TABS findIf {(_x select 0) isEqualTo _tab}) < 0) then {_tab = "fleet"};

[
    _body, [_pad, _padY, _w - 2 * _pad, _rowH * 1.2], DRONES_TABS, _tab, QGVAR(dronesTab), "drones",
    "CONTROL NEEDS THE DATA LINK"
] call FUNC(appPageTabs);

private _top = _padY * 3 + _rowH * 1.2;
private _fullH = _h - _top - _padY;
private _ctx = createHashMapFromArray [["fleet", _fleet], ["pick", _pick], ["rowH", _rowH]];

if (_tab isEqualTo "enemy") then {
    ["stop"] call FUNC(appDronesCamera);
    [_body, [_pad, _top, _w - 2 * _pad, _fullH], _ctx] call FUNC(appDronesEnemy);
} else {
    private _leftW = (_w - 3 * _pad) * PAGE_SPLIT_DRONES;
    private _rightX = _pad * 2 + _leftW;
    [_body, [_pad, _top, _leftW, _fullH], _ctx] call FUNC(appDronesFleet);
    [_body, [_rightX, _top, _w - _rightX - _pad, _fullH], _ctx] call FUNC(appDronesFeed);
};

// LIVE: redraw only when what the rows say changed (FUNC(appDronesKey)) - the
// picture and the HUD keep themselves current without a rebuild.
uiNamespace setVariable [QGVAR(dronesSeen), [] call FUNC(appDronesKey)];

private _existing = uiNamespace getVariable [QGVAR(dronesPFH), -1];
if (_existing >= 0) then {
    [_existing] call CBA_fnc_removePerFrameHandler;
};

uiNamespace setVariable [QGVAR(dronesPFH), [{
    params ["", "_handle"];

    if !(["drones"] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable [QGVAR(dronesPFH), -1];
        ["stop"] call FUNC(appDronesCamera);
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    if (([] call FUNC(appDronesKey)) isEqualTo (uiNamespace getVariable [QGVAR(dronesSeen), ""])) exitWith {};

    ["drones"] call EFUNC(tacpad,openApp);
}, DRONES_REFRESH, []] call CBA_fnc_addPerFrameHandler];
