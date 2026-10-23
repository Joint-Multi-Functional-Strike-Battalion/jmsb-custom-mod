#include "script_component.hpp"
/*
    File: fnc_uiDraw.sqf
    Author: YonV
    Description: Draw the current page.

        EVERY PAGE STARTS FROM A BLANK SHELL. The content controls are hidden,
        the tables emptied, the form forgotten, the buttons cleared - then the
        page function (FUNC(pg<Name>)) places and fills what it needs. A page
        that does not exist says so rather than showing whatever the last
        one left behind.

    Parameters:
        None

    Returns:
        Nothing
*/

disableSerialization;

if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

// ---- blank the shell ------------------------------------------------------
private _hide = [
    PAC_IDC_SUB1, PAC_IDC_SUB2, PAC_IDC_SUB3, PAC_IDC_SUB4, PAC_IDC_SUB5, PAC_IDC_SUB6, PAC_IDC_SUB7, PAC_IDC_SUB8,
    PAC_IDC_TILE_BG1, PAC_IDC_TILE_BG2, PAC_IDC_TILE_BG3, PAC_IDC_TILE_BG4, PAC_IDC_TILE_BG5, PAC_IDC_TILE_BG6,
    PAC_IDC_TILE_LINE1, PAC_IDC_TILE_LINE2, PAC_IDC_TILE_LINE3, PAC_IDC_TILE_LINE4, PAC_IDC_TILE_LINE5, PAC_IDC_TILE_LINE6,
    PAC_IDC_TILE_TXT1, PAC_IDC_TILE_TXT2, PAC_IDC_TILE_TXT3, PAC_IDC_TILE_TXT4, PAC_IDC_TILE_TXT5, PAC_IDC_TILE_TXT6,
    PAC_IDC_LIST, PAC_IDC_LIST_HEAD, PAC_IDC_LIST2, PAC_IDC_LIST2_HEAD, PAC_IDC_LIST3, PAC_IDC_LIST3_HEAD,
    PAC_IDC_TEXT, PAC_IDC_TEXT_HEAD, PAC_IDC_BIGEDIT, PAC_IDC_BIGEDIT_HEAD,
    PAC_IDC_BACK, PAC_IDC_BTN1, PAC_IDC_BTN2, PAC_IDC_BTN3, PAC_IDC_BTN4, PAC_IDC_BTN5, PAC_IDC_BTN6,
    PAC_IDC_FILTER, PAC_IDC_FILTER_LABEL,
    PAC_IDC_CONFIRM_DIM, PAC_IDC_CONFIRM_BOX, PAC_IDC_CONFIRM_TEXT, PAC_IDC_CONFIRM_YES, PAC_IDC_CONFIRM_NO
];
for "_i" from 0 to (PAC_IDC_FORM_ROWS - 1) do {
    _hide append [PAC_IDC_FORM_LABEL(_i), PAC_IDC_FORM_EDIT(_i), PAC_IDC_FORM_COMBO(_i)];
};
{
    private _c = [_x] call FUNC(uiCtrl);
    _c ctrlShow false;
    _c setVariable [QGVAR(onClick), nil];
    _c setVariable [QGVAR(onRow), nil];
    _c setVariable [QGVAR(onChange), nil];
} forEach _hide;
{lnbClear ([_x] call FUNC(uiCtrl))} forEach [PAC_IDC_LIST, PAC_IDC_LIST2, PAC_IDC_LIST3];

GVAR(uiFormKeys) = [];
GVAR(uiFormNext) = 0;
GVAR(uiLive) = false;
GVAR(uiWaiting) = [];
GVAR(uiFilterable) = false;
["", false] call FUNC(uiHint);
["", ""] call FUNC(uiTitle);

[] call FUNC(uiNav);
[[]] call FUNC(uiButtons);          // BACK on its own until the page adds to it

// ---- the page -------------------------------------------------------------
private _fn = missionNamespace getVariable [format [QFUNC(pg%1), GVAR(uiPage)], {}];
if (_fn isEqualTo {}) exitWith {
    [format ["No such page: %1", GVAR(uiPage)], "The nav bar above goes to every page there is."] call FUNC(uiTitle);
    [[]] call FUNC(uiButtons);
};

[] call _fn;
