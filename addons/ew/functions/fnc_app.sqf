#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//EW - the EW app (DESIGN_EW, DESIGN_TABLET_APPS). Four tabs over one
 * frame, the doctrinal split:
 *
 *   OVERVIEW  his kit, the side's picture in numbers, recent threat
 *             warnings, and the map layer switch (FUNC(appOverview))
 *   ES        the spectrum where he stands and the side's tracks - tap one
 *             to see it on the map (FUNC(appEs))
 *   EA        his jammer - mode, target, power, duty, transmit - and decoys
 *             (FUNC(appEa))
 *   EP        his own sets: EMCON per set and how far each is heard
 *             (FUNC(appEp))
 *
 * Everything drawn comes from his slice (FUNC(publish)); every press goes to
 * the server, which owns the state, and comes back in the next slice. It
 * redraws itself every APP_REFRESH_S while the slice or the tab changed,
 * through the appAlive / appIdle pair every live app uses.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ew", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

([_display, "EW - ELECTRONIC WARFARE", APP_W, APP_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _w = (ctrlPosition _body) select 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

// THE TABS, one row across the top.
private _tabs = TABS;
private _tabW = (_w - _pad) / count _tabs;
{
    [_body, [_pad + _forEachIndex * _tabW, _padY, _tabW - _pad, _rowH], _x, _forEachIndex isEqualTo GVAR(tab), {
        params ["_ctrl"];
        GVAR(tab) = _ctrl getVariable [QGVAR(data), TAB_OVERVIEW];
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }, _forEachIndex] call FUNC(appButton);
} forEach _tabs;

private _top = _padY * 2 + _rowH;
[_body, [0, _top, _w, RULE_THICK * pixelH], ["ink"] call EFUNC(tacpad,theme)] call EFUNC(tacpad,drawFill);
_top = _top + _padY * 2;

if (GVAR(mine) isEqualTo []) then {
    [_body, [_pad, _top, _w - 2 * _pad, _rowH], "NO EW PICTURE YET", ["accentText"] call EFUNC(tacpad,theme), TEXT_TITLE, true] call EFUNC(tacpad,drawText);
    [_body, [_pad, _top + _rowH, _w - 2 * _pad, _rowH], "THE SERVER SENDS ONE EVERY DF TICK - EW NEEDS THE RF CORE RUNNING", ["muted"] call EFUNC(tacpad,theme), TEXT_BODY] call EFUNC(tacpad,drawText);
} else {
    switch (GVAR(tab)) do {
        case TAB_ES: {[_body, _top] call FUNC(appEs)};
        case TAB_EA: {[_body, _top] call FUNC(appEa)};
        case TAB_EP: {[_body, _top] call FUNC(appEp)};
        default {[_body, _top] call FUNC(appOverview)};
    };
};

// What this draw is OF, so the loop redraws only on a change.
uiNamespace setVariable [QGVAR(drawn), str [GVAR(mine), GVAR(tab), GVAR(mapLayer)]];

if (GVAR(pfh) >= 0) exitWith {};
GVAR(pfh) = [{
    params ["", "_handle"];
    if !([APP_ID] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        GVAR(pfh) = -1;
    };
    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    if ((str [GVAR(mine), GVAR(tab), GVAR(mapLayer)]) isEqualTo (uiNamespace getVariable [QGVAR(drawn), ""])) exitWith {};
    [APP_ID] call EFUNC(tacpad,openApp);
}, APP_REFRESH_S, []] call CBA_fnc_addPerFrameHandler;
