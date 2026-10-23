#include "script_component.hpp"
/*
    File: fnc_uiHost.sqf
    Author: YonV
    Description: Opens TAC//PAC INSIDE THE TABLET (user, 2026-10-20: "all apps
        need to be inside the tablet"). The page's shell group
        (ui/pac.inc.hpp, GVAR(shell)) is created on the device dialog at the
        tablet's map area - the tacpad's host rectangle - and adopted as the
        tablet's open app, so the device bar, the tiles and the net row stay
        round it, ESC and CLOSE take the page down and leave the tablet up,
        and a tile replaces it like any other app.

        THE SAME CONTROLS AS THE DIALOG. The shell is one root class with
        every control as a child, so this creates exactly what the dialog
        declares, handlers and all; every page then lays itself out in
        fractions of the shell (FUNC(uiPlace)), which here is the map area.
        What the pages do not place - the bar, the title, the hint, the
        confirm box - is put at its config fractions of the shell below, and
        type is scaled by the host's ratio to the safe zone (HOST_K), so the
        website's proportions survive a screen two thirds the size.

        Edits are children of the device dialog, which is a dialog, so they
        take keyboard focus there.

        Called by FUNC(uiOpen) when the tacpad's host is a device that is
        open; the dialog is what opens everywhere else.

    Parameters:
        None

    Returns:
        Whether it opened <BOOL>
*/

disableSerialization;

private _display = HOST_DISPLAY;
if (isNull _display) exitWith {false};

// One page. A second shell would leave every lookup answering from whichever
// the engine likes.
private _old = uiNamespace getVariable [QGVAR(shell), controlNull];
if (!isNull _old) then {ctrlDelete _old};

// THE LAYOUT, ONCE PER SESSION: each child's config rectangle as fractions of
// the safe zone - which is what the shell's children are written in - and its
// type height. The config holds expressions ("0.012 * safezoneW"), which the
// engine evaluates for a dialog and nothing evaluates for a ctrlCreate'd
// child resized afterwards, so they are evaluated here.
private _layout = uiNamespace getVariable [QGVAR(uiHostLayout), []];
if (_layout isEqualTo []) then {
    private _fnc_value = {
        params ["_entry"];
        if (isNumber _entry) exitWith {getNumber _entry};
        if (isText _entry) exitWith {
            private _v = call compile getText _entry;
            [0, _v] select (_v isEqualType 0)
        };
        -1
    };
    {
        private _idc = getNumber (_x >> "idc");
        if (_idc < 0) then {continue};
        private _rect = [
            ([_x >> "x"] call _fnc_value) / safeZoneW,
            ([_x >> "y"] call _fnc_value) / safeZoneH,
            ([_x >> "w"] call _fnc_value) / safeZoneW,
            ([_x >> "h"] call _fnc_value) / safeZoneH
        ];
        private _font = [_x >> "sizeEx"] call _fnc_value;
        if (_font <= 0) then {_font = [_x >> "size"] call _fnc_value};
        _layout pushBack [_idc, _rect, _font];
    } forEach ("true" configClasses (configFile >> QGVAR(shell) >> "controls"));
    uiNamespace setVariable [QGVAR(uiHostLayout), _layout];
};

private _shell = _display ctrlCreate [QGVAR(shell), PAC_IDC_SHELL];
_shell ctrlSetPosition HOST_RECT;
_shell ctrlCommit 0;
uiNamespace setVariable [QGVAR(shell), _shell];

private _k = HOST_K;
{
    _x params ["_idc", "_rect", "_font"];
    private _c = _shell controlsGroupCtrl _idc;
    if (isNull _c) then {continue};
    _rect params ["_fx", "_fy", "_fw", "_fh"];
    _c ctrlSetPosition [_fx * HOST_W, _fy * HOST_H, _fw * HOST_W, _fh * HOST_H];
    if (_font > 0) then {_c ctrlSetFontHeight (_font * _k)};
    _c ctrlCommit 0;
} forEach _layout;

// THE TABLET'S OPEN APP - panels hidden under it, ESC and a map press close
// it, a tile replaces it. A shell deleted by any of those is a null control,
// which is how every PAC function knows the page is gone (FUNC(uiCtrl)).
[PAC_APP, _shell] call EFUNC(tacpad,appHost);

[] call FUNC(uiLoaded);

true
