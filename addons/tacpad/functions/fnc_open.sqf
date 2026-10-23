#include "script_component.hpp"
/*
 * Author: JMSB
 * The host opened. Builds every panel the player has switched on, then starts
 * the one refresh loop they all share.
 *
 * THE HOST IS THE MAP OR A DEVICE. On the vanilla map this runs off the Map
 * event and lays out in the safe zone. In tablet mode jmfsb_devices calls it
 * after FUNC(setHost) has handed over its dialog and screen rectangle, and the
 * same panels are built there - see shared.inc.hpp.
 *
 * One loop, not one per panel: eight per-frame handlers ticking at eight
 * different periods is eight chances to leave one running after the map shuts,
 * and the map is open for seconds at a time anyway.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */

if (!hasInterface || {!GVAR(enabled)}) exitWith {};

// The native host is the safe zone as it is NOW - a resolution change between
// two map opens would otherwise lay the suite out for the old one.
if (HOST_NATIVE) then {
    [] call FUNC(setHost);
};

private _display = HOST_DISPLAY;
if (isNull _display) exitWith {};

[] call FUNC(close);

// NO INPUT PLUMBING HERE. Every clickable thing in the suite is an RscButton
// carrying its own ButtonClick handler - see FUNC(hotspot) - which is the whole
// of it. The map control's own mouse handlers were hooked here once, to feed a
// dispatcher that hit-tested registered rectangles, and that could never have
// worked: the buttons consumed the clicks before the map saw them.
private _built = 0;
{
    private _panel = GVAR(panels) get _x;
    if (!isNil "_panel") then {
        // Each panel's own on/off setting lives in the addon that registered
        // it, under a name derived from the id - the shell does not need to
        // know what the setting is called to ask whether it is on.
        private _wanted = missionNamespace getVariable [format ["jmfsb_tacpad_apps_show_%1", _x], true];

        // AND WHETHER IT IS THEIRS TO HAVE AT ALL, which is a different question
        // from whether they want it. The admin strip is registered by
        // jmfsb_adminpanel with a condition on the admin list; nobody else gets
        // a button they would only be refused by. Checked on every map open, so
        // a promotion mid-mission takes effect on the next one.
        if (_wanted) then {
            _wanted = call (_panel getOrDefault ["condition", {true}]);
        };

        // SHOW ALL has to stay reachable. A pinned panel ignores the master
        // switch, which is the only reason the settings strip can be pressed a
        // second time to bring everything back.
        if (GVAR(hideAll) && {!(_x in GVAR(pinned))}) then {_wanted = false};

        // NOT ON THIS DEVICE. A host's layout table maps a panel to [] when
        // the device has no place for it: the tablet draws the live tiles in
        // its own row, and the vehicle tablet shows ON BOARD where the squad
        // rail would be - see FUNC(setHost).
        if (_x in GVAR(hostPlaces) && {(GVAR(hostPlaces) get _x) isEqualTo []}) then {_wanted = false};

        if (_wanted) then {
            [_display, _panel] call FUNC(build);
            _built = _built + 1;
        };
    };
} forEach GVAR(order);

INFO_3("open: %1 panel(s) built on host %2 (%3 registered)",_built,GVAR(host),count GVAR(order));
if (_built == 0) exitWith {};

// THE OPEN APP GOES BACK ON TOP. Every panel has just been created, which makes
// them the newest controls on the display - and a screen the player is looking
// at would be sitting under them, unpressable. Arma has no way to raise a
// control, so the app is opened again: it is a redraw either way.
private _app = uiNamespace getVariable [QGVAR(appCurrent), ""];
if (_app isNotEqualTo "") then {
    [_app] call FUNC(openApp);
};

GVAR(tickPFH) = [{
    params ["", "_handle"];

    if (isNull (HOST_DISPLAY)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        GVAR(tickPFH) = -1;
    };

    [] call FUNC(diaryWatch);

    // NOTHING REDRAWS BEHIND AN OPEN APP. A refresher deletes and recreates its
    // panel's contents, and a control deleted between a press and its release
    // never raises a click - so a panel ticking away behind a screen is a
    // standing chance of eating a press meant for the screen. The panels are a
    // glance at the map and the map is covered; there is nothing to look at.
    //
    // They pick up again the moment the app closes, and each refresher is a full
    // redraw rather than a delta, so nothing has to be caught up.
    if ((uiNamespace getVariable [QGVAR(appCurrent), ""]) isNotEqualTo "") exitWith {};

    private _now = diag_tickTime;
    {
        _y params ["", "_body", ""];
        private _panel = GVAR(panels) get _x;
        if (!isNil "_panel" && {!isNull _body}) then {
            private _refresher = _panel get "refresher";
            if (_refresher isNotEqualTo {}) then {
                private _due = _panel getOrDefault ["due", 0];
                if (_now >= _due) then {
                    _panel set ["due", _now + (_panel get "period")];
                    [_body, _x] call _refresher;
                };
            };
        };
    } forEach GVAR(open);
}, 0.25, []] call CBA_fnc_addPerFrameHandler;
