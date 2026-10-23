#include "script_component.hpp"
/*
    File: fnc_uiButtons.sqf
    Author: YonV
    Description: The actions row along the foot - the website's `.actions`.
        BACK on the left whenever there is a page to go back to, then up to
        six buttons the page names. A destructive one is drawn the website's
        way: red text, no fill, so the eye has to choose it.

    Parameters:
        0: Buttons <ARRAY> - [[label, code, hot], ...]; code is called with
           [control]; hot (optional) draws it red

    Returns:
        Nothing
*/

params [["_buttons", [], [[]]]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

private _back = [PAC_IDC_BACK] call FUNC(uiCtrl);
if (count GVAR(uiHistory) > 1) then {
    [_back, PAC_UI_X, 0.940, 0.090, 0.034] call FUNC(uiPlace);
    _back setVariable [QGVAR(onClick), {[] call FUNC(uiBack)}];
} else {
    _back ctrlShow false;
};

private _idcs = [PAC_IDC_BTN1, PAC_IDC_BTN2, PAC_IDC_BTN3, PAC_IDC_BTN4, PAC_IDC_BTN5, PAC_IDC_BTN6];
private _w = 0.140;
private _gap = 0.008;
{
    private _c = [_x] call FUNC(uiCtrl);
    if (_forEachIndex >= count _buttons) then {
        _c ctrlShow false;
        _c setVariable [QGVAR(onClick), nil];
        continue;
    };
    (_buttons # _forEachIndex) params ["_label", "_code", ["_hot", false]];
    [_c, 0.108 + _forEachIndex * (_w + _gap), 0.940, _w, 0.034] call FUNC(uiPlace);
    _c ctrlSetText _label;
    // a destructive one is FILLED red with dark text - an outline in a row
    // of filled buttons read as a broken one (2026-09-10: "color off")
    if (_hot) then {
        _c ctrlSetTextColor [0.043, 0.055, 0.067, 1];
        _c ctrlSetBackgroundColor [0.894, 0.341, 0.290, 1];
    } else {
        _c ctrlSetTextColor [0.043, 0.055, 0.067, 1];
        _c ctrlSetBackgroundColor [0.576, 0.812, 0.447, 1];
    };
    _c setVariable [QGVAR(onClick), _code];
} forEach _idcs;
