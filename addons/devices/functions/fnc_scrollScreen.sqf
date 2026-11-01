#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet's arrows scroll the screen (user, 2026-10-25: "would be nice if
 * they scrolled screens like notification logs"). LEFT (numpad 0) is up,
 * RIGHT (numpad .) is down, a page short of the visible height per press.
 *
 * WHICH SCREEN: the scrolling list under the mouse when there is one; else,
 * with an app, a message view or the notices log open, the biggest list that
 * has more than it shows. Nothing to scroll answers false, and the arrows
 * step the active net as before (FUNC(softKey)) - so on the home screen they
 * still change net.
 *
 * Arguments:
 * 0: Step - -1 up, 1 down <NUMBER>
 *
 * Return Value:
 * Scrolled - the key is consumed <BOOL>
 *
 * Example:
 * [1] call jmfsb_devices_fnc_scrollScreen
 *
 * Public: No
 */

params [["_step", 0, [0]]];

private _display = findDisplay IDD_TABLET;
if (isNull _display || _step isEqualTo 0) exitWith {false};

// A group's place on the screen and whether it shows, through its parents.
private _fnc_screenRect = {
    params ["_ctrl"];
    (ctrlPosition _ctrl) params ["_x", "_y", "_w", "_h"];
    private _shown = ctrlShown _ctrl;
    private _parent = ctrlParentControlsGroup _ctrl;
    while {!isNull _parent} do {
        (ctrlPosition _parent) params ["_px", "_py"];
        _x = _x + _px;
        _y = _y + _py;
        _shown = _shown && {ctrlShown _parent};
        _parent = ctrlParentControlsGroup _parent;
    };
    [_shown, [_x, _y, _w, _h]]
};

// Every list that shows and holds more than it shows: [group, rect, content height].
private _lists = [];
{
    private _group = _x;
    if ((ctrlScrollValues _group) select 0 >= 0) then {
        ([_group] call _fnc_screenRect) params ["_shown", "_rect"];
        if (_shown) then {
            private _bottom = 0;
            {
                (ctrlPosition _x) params ["", "_cy", "", "_ch"];
                _bottom = _bottom max (_cy + _ch);
            } forEach (allControls _display select {(ctrlParentControlsGroup _x) isEqualTo _group});
            if (_bottom > (_rect select 3)) then {_lists pushBack [_group, _rect, _bottom]};
        };
    };
} forEach (allControls _display select {ctrlType _x isEqualTo CT_CONTROLS_GROUP});
if (_lists isEqualTo []) exitWith {false};

getMousePosition params ["_mx", "_my"];
private _under = _lists select {
    (_x select 1) params ["_lx", "_ly", "_lw", "_lh"];
    _mx >= _lx && _mx <= _lx + _lw && _my >= _ly && _my <= _ly + _lh
};
// The smallest (true) or the biggest (false) of the lists, by its area on screen.
private _fnc_byArea = {
    params ["_from", "_smallest"];
    private _keyed = [];
    {
        _keyed pushBack [((_x select 1) select 2) * ((_x select 1) select 3), _forEachIndex];
    } forEach _from;
    _keyed sort _smallest;
    _from select ((_keyed select 0) select 1)
};
private _pick = [];
if (_under isNotEqualTo []) then {
    // The innermost: the smallest of the lists under the mouse.
    _pick = [_under, true] call _fnc_byArea;
} else {
    private _open = (uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo ""
        || {missionNamespace getVariable [QEGVAR(tacpad_apps,readerLog), false]}
        || {!isNull (_display displayCtrl IDC_RD_ROOT)};
    if (_open) then {
        _pick = [_lists, false] call _fnc_byArea;
    };
};
if (_pick isEqualTo []) exitWith {false};

_pick params ["_group", "_rect", "_bottom"];
private _seen = _rect select 3;
private _now = (ctrlScrollValues _group) select 0;
private _to = ((_now + _step * SCROLL_PAGE * _seen / (_bottom - _seen)) max 0) min 1;
_group ctrlSetScrollValues [_to, -1];
true
