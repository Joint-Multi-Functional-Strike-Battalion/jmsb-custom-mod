#include "script_component.hpp"
/*
    File: fnc_uiList.sqf
    Author: YonV
    Description: Fill one of the tables - the website's `table.grid`.

        REAL COLUMNS. The control is a CT_LISTNBOX, so the columns line up
        the way a table's do; the header is row 0 of the same control in the
        website's faint capitals, so it cannot drift from the data under it.
        When the rows are links (a click handler was given) the first column
        is in the accent, as a link is.

        An optional heading above the table is the website's <h2>: small,
        uppercase, in the accent.

    Parameters:
        0: The list idc <NUMBER> - PAC_IDC_LIST, PAC_IDC_LIST2 or PAC_IDC_LIST3
        1: Column headers <ARRAY of STRING> - [] for none
        2: Column positions <ARRAY of NUMBER> - fractions of the width
        3: Rows <ARRAY> - [[cells, data, colour], ...]; cells is an array of
           strings, data the string the click handler gets, colour optional
        4: Click handler <CODE> - called with [data, row]; {} for a plain table
        5: y <NUMBER>
        6: h <NUMBER>
        7: Heading <STRING> (optional)
        8: x <NUMBER> (optional, default the content column)
        9: w <NUMBER> (optional, default the content width)

    Returns:
        The list control <CONTROL>
*/

params [
    ["_idc", PAC_IDC_LIST, [0]],
    ["_headers", [], [[]]],
    ["_cols", [0], [[]]],
    ["_rows", [], [[]]],
    ["_onRow", {}, [{}]],
    ["_y", PAC_UI_TOP, [0]],
    ["_h", 0.3, [0]],
    ["_heading", "", [""]],
    ["_left", PAC_UI_X, [0]],
    ["_w", PAC_UI_W, [0]]
];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {controlNull};

private _head = [_idc + 1] call FUNC(uiCtrl);
if (_heading isNotEqualTo "") then {
    [_head, _left, _y, _w, 0.026] call FUNC(uiPlace);
    _head ctrlSetStructuredText parseText format ["<t color='#93cf72' size='0.7'>%1</t>", [toUpper _heading] call FUNC(uiEsc)];
    _y = _y + 0.028;
    _h = _h - 0.028;
} else {
    _head ctrlShow false;
};

private _list = [_idc] call FUNC(uiCtrl);
[_list, _left, _y, _w, _h max 0.03] call FUNC(uiPlace);

GVAR(uiFilling) = true;
lnbClear _list;
_list lnbSetColumnsPos _cols;

private _hasHeader = _headers isNotEqualTo [];
if (_hasHeader) then {
    private _r = _list lnbAddRow (_headers apply {toUpper _x});
    for "_c" from 0 to ((count _headers) - 1) do {
        _list lnbSetColor [[_r, _c], [0.361, 0.404, 0.451, 1]];
    };
};

private _link = _onRow isNotEqualTo {};
{
    _x params [["_cells", [], [[]]], ["_data", "", [""]], ["_colour", [], [[]]]];
    private _r = _list lnbAddRow (_cells apply {if (_x isEqualType "") then {_x} else {str _x}});
    _list lnbSetData [[_r, 0], _data];
    if (_colour isNotEqualTo []) then {
        for "_c" from 0 to ((count _cells) - 1) do {_list lnbSetColor [[_r, _c], _colour]};
    } else {
        if (_link) then {_list lnbSetColor [[_r, 0], [0.576, 0.812, 0.447, 1]]};
        for "_c" from 1 to ((count _cells) - 1) do {_list lnbSetColor [[_r, _c], [0.890, 0.914, 0.937, 1]]};
    };
} forEach _rows;
_list lnbSetCurSelRow -1;
GVAR(uiFilling) = false;

_list setVariable [QGVAR(hasHeader), _hasHeader];
_list setVariable [QGVAR(onRow), _onRow];
_list
