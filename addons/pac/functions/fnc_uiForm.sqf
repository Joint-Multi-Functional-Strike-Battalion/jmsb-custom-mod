#include "script_component.hpp"
/*
    File: fnc_uiForm.sqf
    Author: YonV
    Description: Lay out a form - the website's `.fields`: a label, then the
        control, one row each, read back by FUNC(uiFormRead).

        KINDS
            t   one line of text
            m   several lines (the row is three high; extra = how many)
            n   a number (typed as text, read back as a number)
            c   a choice - extra = [[value, label], ...]
            b   yes / no
            r   read only

        Rows are numbered on from where the last form left off, so two forms
        side by side on one page are one form to FUNC(uiFormRead).

    Parameters:
        0: Rows <ARRAY> - [[key, label, kind, value, extra], ...]
        1: y <NUMBER> - where the first row goes
        2: x <NUMBER> (optional, default the content column)
        3: w <NUMBER> (optional, default the content width)
        4: Label width <NUMBER> (optional)

    Returns:
        y under the last row <NUMBER>
*/

params [
    ["_rows", [], [[]]],
    ["_y", PAC_UI_TOP, [0]],
    ["_left", PAC_UI_X, [0]],
    ["_w", PAC_UI_W, [0]],
    ["_labelW", PAC_UI_LABEL_W, [0]]
];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {_y};

private _cx = _left + _labelW + PAC_UI_GAP;
private _cw = _w - _labelW - PAC_UI_GAP;

GVAR(uiFilling) = true;
{
    _x params [["_key", "", [""]], ["_label", "", [""]], ["_kind", "t", [""]], ["_value", ""], ["_extra", []]];
    private _n = GVAR(uiFormNext);
    if (_n >= PAC_IDC_FORM_ROWS) exitWith {
        WARNING_1("form has more than %1 rows - the rest are not drawn",PAC_IDC_FORM_ROWS);
    };
    GVAR(uiFormNext) = _n + 1;

    private _h = PAC_UI_ROW;
    if (_kind isEqualTo "m") then {
        private _lines = [3, _extra] select (_extra isEqualType 0);
        _h = PAC_UI_ROW * _lines;
    };

    private _lab = [PAC_IDC_FORM_LABEL(_n)] call FUNC(uiCtrl);
    [_lab, _left, _y, _labelW, PAC_UI_ROW] call FUNC(uiPlace);
    _lab ctrlSetText _label;

    private _edit = [PAC_IDC_FORM_EDIT(_n)] call FUNC(uiCtrl);
    private _combo = [PAC_IDC_FORM_COMBO(_n)] call FUNC(uiCtrl);
    _edit setVariable [QGVAR(onChange), nil];
    _combo setVariable [QGVAR(onChange), nil];

    switch (_kind) do {
        case "c";
        case "b": {
            _edit ctrlShow false;
            [_combo, _cx, _y, _cw, PAC_UI_ROW] call FUNC(uiPlace);
            lbClear _combo;
            private _opts = _extra;
            if (_kind isEqualTo "b") then {_opts = [["true", "yes"], ["false", "no"]]};
            private _want = if (_value isEqualType true) then {["false", "true"] select _value} else {
                if (_value isEqualType "") then {_value} else {str _value}
            };
            private _sel = 0;
            {
                _x params [["_v", ""], ["_l", ""]];
                if !(_v isEqualType "") then {_v = str _v};
                if (_l isEqualTo "") then {_l = _v};
                private _i = _combo lbAdd _l;
                _combo lbSetData [_i, _v];
                if (_v isEqualTo _want) then {_sel = _i};
            } forEach _opts;
            _combo lbSetCurSel _sel;
        };
        default {
            _combo ctrlShow false;
            [_edit, _cx, _y, _cw, _h] call FUNC(uiPlace);
            private _text = if (_value isEqualType "") then {_value} else {
                if (_value isEqualType []) then {_value joinString ", "} else {str _value}
            };
            _edit ctrlSetText _text;
            _edit ctrlEnable (_kind isNotEqualTo "r");
            _edit ctrlSetTextColor ([[0.890, 0.914, 0.937, 1], [0.545, 0.592, 0.639, 1]] select (_kind isEqualTo "r"));
        };
    };

    GVAR(uiFormKeys) pushBack [_key, _kind, _n];
    _y = _y + _h + PAC_UI_GAP;
} forEach _rows;
GVAR(uiFilling) = false;

_y
