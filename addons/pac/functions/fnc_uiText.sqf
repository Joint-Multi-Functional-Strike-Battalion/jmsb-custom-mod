#include "script_component.hpp"
/*
    File: fnc_uiText.sqf
    Author: YonV
    Description: A block of prose on the page - the website's `.note` or a
        card of text - with an optional heading over it.

    Parameters:
        0: Text <STRING> - plain; line breaks are kept
        1: y <NUMBER>
        2: h <NUMBER>
        3: Heading <STRING> (optional)
        4: x <NUMBER> (optional)
        5: w <NUMBER> (optional)
        6: Dim <BOOL> (optional) - grey, for a note

    Returns:
        Nothing
*/

params [
    ["_text", "", [""]],
    ["_y", PAC_UI_TOP, [0]],
    ["_h", 0.1, [0]],
    ["_heading", "", [""]],
    ["_left", PAC_UI_X, [0]],
    ["_w", PAC_UI_W, [0]],
    ["_dim", false, [false]]
];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

private _head = [PAC_IDC_TEXT_HEAD] call FUNC(uiCtrl);
if (_heading isNotEqualTo "") then {
    [_head, _left, _y, _w, 0.026] call FUNC(uiPlace);
    _head ctrlSetStructuredText parseText format ["<t color='#93cf72' size='0.7'>%1</t>", [toUpper _heading] call FUNC(uiEsc)];
    _y = _y + 0.028;
    _h = _h - 0.028;
} else {
    _head ctrlShow false;
};

private _c = [PAC_IDC_TEXT] call FUNC(uiCtrl);
[_c, _left, _y, _w, _h max 0.03] call FUNC(uiPlace);
private _safe = [_text] call FUNC(uiEsc);
_safe = [_safe, endl, "<br/>"] call CBA_fnc_replace;
_safe = [_safe, toString [10], "<br/>"] call CBA_fnc_replace;
_c ctrlSetStructuredText parseText format [
    "<t color='%1'>%2</t>", ["#e3e9ef", "#8b97a3"] select _dim, _safe
];
