#include "script_component.hpp"
/*
    File: fnc_uiNav.sqf
    Author: YonV
    Description: The nav bar - the website's, in its order and its words,
        minus Media, Branding and My details (user, 2026-09-09).

        THE PAGES THAT NEED THE DATABASE - Applications, PAC actions, Mongo
        docs - are only on the bar when this server has the service, because
        without it there is nothing behind them and a button that does
        nothing is worse than no button. The rest close up the gap.

        The page you are on is in the accent with the underline under it,
        exactly as `a.on` is on the website.

    Parameters:
        None

    Returns:
        Nothing
*/

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

private _svc = "service" in ((missionNamespace getVariable [QGVAR(summary), createHashMap]) getOrDefault ["backend", ""]);

private _items = [
    ["DASHBOARD", "dashboard", true],
    ["ROSTER", "roster", true],
    ["APPLICATIONS", "applications", _svc],
    ["PAC ACTIONS", "tickets", _svc],
    ["ORDERS", "orders", true],
    ["CONFIGS", "configs", true],
    ["TEMPLATES", "templates", true],
    ["ORBAT", "orbat", true],
    ["MONGO DOCS", "docs", _svc],
    ["BACKUP", "backup", true]
] select {_x # 2};

// Which page on the bar the current page belongs under - a player page is
// the roster's, a role page the ORBAT's.
private _under = switch (GVAR(uiPage)) do {
    case "player";
    case "addOperator": {"roster"};
    case "application": {"applications"};
    case "ticket": {"tickets"};
    case "order";
    case "newOrder": {"orders"};
    case "record";
    case "recordItem": {"configs"};
    case "template";
    case "templateItem";
    case "welcome";
    case "arsenalList";
    case "deckTemplate";
    case "ticketKind";
    case "scheme": {"templates"};
    case "role";
    case "squad";
    case "platoon";
    case "orbatOne";
    case "net";
    case "radioRow";
    case "slot": {"orbat"};
    case "doc": {"docs"};
    default {GVAR(uiPage)};
};

private _idcs = [PAC_IDC_NAV1, PAC_IDC_NAV2, PAC_IDC_NAV3, PAC_IDC_NAV4, PAC_IDC_NAV5, PAC_IDC_NAV6, PAC_IDC_NAV7, PAC_IDC_NAV8, PAC_IDC_NAV9, PAC_IDC_NAV10];
private _w = 0.090;
private _gap = 0.006;
private _ul = [PAC_IDC_NAV_UL] call FUNC(uiCtrl);
_ul ctrlShow false;

{
    private _c = [_x] call FUNC(uiCtrl);
    if (_forEachIndex >= count _items) then {
        _c ctrlShow false;
        _c setVariable [QGVAR(onClick), nil];
        continue;
    };
    (_items # _forEachIndex) params ["_label", "_page"];
    private _x0 = PAC_UI_X + _forEachIndex * (_w + _gap);
    [_c, _x0, 0.040, _w, 0.028] call FUNC(uiPlace);
    _c ctrlSetText _label;
    private _on = _page isEqualTo _under;
    _c ctrlSetTextColor ([[0.545, 0.592, 0.639, 1], [0.576, 0.812, 0.447, 1]] select _on);
    if (_on) then {[_ul, _x0, 0.070, _w, 0.003] call FUNC(uiPlace)};
    _c setVariable [QGVAR(page), _page];
    _c setVariable [QGVAR(onClick), {
        params ["_ctrl"];
        // A bar click starts a fresh trail, the way a new address does.
        GVAR(uiHistory) = [];
        [_ctrl getVariable [QGVAR(page), "dashboard"]] call FUNC(uiGo);
    }];
} forEach _idcs;
