#include "script_component.hpp"
/*
 * Author: YonV
 * Eden attributeLoad handler for the class picker (jmfsb_ClassPick_*).
 *
 * Fills the listbox (IDC 100) from FUNC(listClasses), restores the stored
 * selection, and wires the two filter strips: Side (1200/1210) and Faction
 * (1201/1211) - or Type and Source for ammo, which has neither. Ticks on
 * rows a filter hides are kept in a set on the display, the way ALiVE's
 * picker does it, so cycling a filter never loses a choice.
 *
 * The stored value is read from Eden's _value (authoritative), then the
 * display's value slot, then the module logic. Anything stored that the
 * list does not know is shown as "(unrecognised) ..." at the top, ticked,
 * so an open-and-OK never silently rewrites a mission.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the attribute's controls group
 * 1: Kind <STRING> - see FUNC(listClasses)
 * 2: Variable name <STRING> - unused; the value slot carries it (kept for symmetry)
 * 3: Title <STRING>
 * 4: Side lock <NUMBER> - -1 free, else the side the strip is fixed to
 * 5: Single select <BOOL>
 * 6: Stored value <STRING> - Eden's _value
 *
 * Return Value: None
 *
 * Public: No
 */

params [
    ["_display", displayNull, [displayNull, controlNull]],
    ["_kind", "vehicle", [""]],
    ["_varName", "", [""]],
    ["_title", "Classes:", [""]],
    ["_sideLock", -1, [0]],
    ["_single", false, [false]],
    ["_sqmValue", "", [""]]
];
if (isNull _display) exitWith {};
private _list = _display controlsGroupCtrl 100;
if (isNull _list) exitWith {};

// THE TITLE SAYS WHAT IS PICKED (user, 2026-11-08): "<title> <class>", or the
// first few and how many more, or "(none)" - kept current on every click.
_display setVariable [QGVAR(pickTitleText), _title];
_display setVariable [QGVAR(pickTitle), {
    params ["_disp"];
    private _titleCtrl = _disp controlsGroupCtrl 101;
    if (isNull _titleCtrl) exitWith {};
    private _sel = _disp getVariable [QGVAR(pickSel), []];
    private _shown = (_sel select [0, PICK_TITLE_MAX]) joinString ", ";
    if (count _sel > PICK_TITLE_MAX) then {_shown = format ["%1 +%2", _shown, count _sel - PICK_TITLE_MAX]};
    if (_sel isEqualTo []) then {_shown = "(none)"};
    _titleCtrl ctrlSetText format ["%1 %2", _disp getVariable [QGVAR(pickTitleText), ""], _shown];
}];

// ---- the stored value ----------------------------------------------------
private _value = "";
private _edenValue = _display getVariable ["value", ""];
if (_edenValue isEqualType "") then { _value = _edenValue };
if (_sqmValue isNotEqualTo "") then { _value = _sqmValue };
private _selected = [];
{
    private _t = trim _x;
    if (_t isNotEqualTo "") then { _selected pushBackUnique _t };
} forEach (_value splitString ",");

// ---- the rows and the filter axes ---------------------------------------
private _rows = [_kind] call FUNC(listClasses);
private _isAmmo = _kind isEqualTo "ammo";
private _aOpts = []; private _bOpts = [];
if (_isAmmo) then {
    // Type / Source
    _aOpts = ["All"];
    { _aOpts pushBackUnique (_x select 4) } forEach _rows;
    _bOpts = ["All"];
    { _bOpts pushBackUnique (_x select 5) } forEach _rows;
} else {
    _aOpts = [-9, 1, 0, 2, 3, -1];   // All, BLUFOR, OPFOR, Independent, Civilian, no side
    _bOpts = ["All"];                // factions are recomputed from the side in view
};
private _aIdx = 0;
if (!_isAmmo && {_sideLock > -1}) then { _aIdx = _aOpts find _sideLock };
_display setVariable [QGVAR(pickRows), _rows];
_display setVariable [QGVAR(pickSel), _selected];
_display setVariable [QGVAR(pickAmmo), _isAmmo];
_display setVariable [QGVAR(pickSingle), _single];
_display setVariable [QGVAR(pickAOpts), _aOpts];
_display setVariable [QGVAR(pickAIdx), _aIdx];
_display setVariable [QGVAR(pickBOpts), _bOpts];
_display setVariable [QGVAR(pickBIdx), 0];
_display setVariable [QGVAR(pickSideLock), _sideLock];

private _sideName = {
    switch (_this) do {
        case -9: {"All"};
        case 0: {"OPFOR"};
        case 1: {"BLUFOR"};
        case 2: {"Independent"};
        case 3: {"Civilian"};
        default {"no side"};
    }
};
_display setVariable [QGVAR(pickSideName), _sideName];

private _populate = {
    params ["_disp"];
    private _list = _disp controlsGroupCtrl 100;
    if (isNull _list) exitWith {};
    private _rows = _disp getVariable [QGVAR(pickRows), []];
    private _sel = _disp getVariable [QGVAR(pickSel), []];
    private _isAmmo = _disp getVariable [QGVAR(pickAmmo), false];
    private _aOpts = _disp getVariable [QGVAR(pickAOpts), []];
    private _aIdx = _disp getVariable [QGVAR(pickAIdx), 0];
    private _sideName = _disp getVariable QGVAR(pickSideName);
    private _a = _aOpts param [_aIdx, -9];

    // Strip A narrows first; strip B's options are what is left.
    private _inA = if (_isAmmo) then {
        if (_a isEqualTo "All") then {_rows} else {_rows select {(_x select 4) isEqualTo _a}}
    } else {
        if (_a isEqualTo -9) then {_rows} else {_rows select {(_x select 2) isEqualTo _a}}
    };
    private _bOpts = ["All"];
    if (_isAmmo) then {
        { _bOpts pushBackUnique (_x select 5) } forEach _inA;
    } else {
        { if ((_x select 3) isNotEqualTo "") then { _bOpts pushBackUnique (_x select 3) } } forEach _inA;
    };
    private _bIdx = (_disp getVariable [QGVAR(pickBIdx), 0]) min (count _bOpts - 1);
    _disp setVariable [QGVAR(pickBOpts), _bOpts];
    _disp setVariable [QGVAR(pickBIdx), _bIdx];
    private _b = _bOpts select _bIdx;
    private _shown = if (_b isEqualTo "All") then {_inA} else {
        _inA select {(_x select ([3, 5] select _isAmmo)) isEqualTo _b}
    };

    private _la = _disp controlsGroupCtrl 1200;
    private _lb = _disp controlsGroupCtrl 1201;
    if (!isNull _la) then {
        _la ctrlSetText (if (_isAmmo) then {format ["Type: %1", _a]} else {
            format ["Side: %1%2", _a call _sideName, ["", " (fixed)"] select ((_disp getVariable [QGVAR(pickSideLock), -1]) > -1)]
        });
    };
    if (!isNull _lb) then {
        private _bText = _b;
        if (!_isAmmo && _b isNotEqualTo "All") then {
            private _dn = getText (configFile >> "CfgFactionClasses" >> _b >> "displayName");
            _bText = [_dn, _b] select (_dn isEqualTo "");
        };
        _lb ctrlSetText (format [["Faction: %1", "Source: %1"] select _isAmmo, _bText]);
    };

    _disp setVariable [QGVAR(pickBusy), true];
    lbClear _list;
    private _first = -1;
    private _single = _disp getVariable [QGVAR(pickSingle), false];
    private _known = createHashMap;
    { _known set [toLower (_x select 0), true] } forEach _rows;
    {
        if !((toLower _x) in _known) then {
            private _i = _list lbAdd format ["(unrecognised) %1", _x];
            _list lbSetData [_i, _x];
            if (_first < 0) then {_first = _i};
            if (!_single) then { _list lbSetSelected [_i, true] };
        };
    } forEach _sel;
    private _selLower = createHashMap;
    { _selLower set [toLower _x, true] } forEach _sel;
    // THE PICK SHOWS (user, 2026-11-08: "the selectors like transport do not
    // show what is been selected"): the picked rows first, so they are in view
    // when the list opens, and a single-select list's pick made its current
    // row - lbSetSelected does nothing on a list without LB_MULTI.
    private _picked = _shown select {(toLower (_x select 0)) in _selLower};
    {
        _x params ["_cn", "_dn", "_side", "_fac", "_cat", "_src"];
        private _label = if (_isAmmo) then {format ["%1 [%2] %3", _cn, _cat, _src]} else {
            format ["%1 | %2 [%3%4] %5", _cn, _dn, _cat, ["", " " + _fac] select (_fac isNotEqualTo ""), _src]
        };
        private _i = _list lbAdd _label;
        _list lbSetData [_i, _cn];
        if ((toLower _cn) in _selLower) then {
            if (_first < 0) then {_first = _i};
            if (!_single) then { _list lbSetSelected [_i, true] };
        };
    } forEach (_picked + (_shown - _picked));
    if (_single && _first >= 0) then { _list lbSetCurSel _first };
    [_disp] call (_disp getVariable QGVAR(pickTitle));
    _disp setVariable [QGVAR(pickBusy), false];
};
_display setVariable [QGVAR(pickPopulate), _populate];
[_display] call _populate;

private _edit = _display controlsGroupCtrl 102;
if (!isNull _edit) then { _edit ctrlSetText "" };

// ---- the buttons ---------------------------------------------------------
private _btnA = _display controlsGroupCtrl 1210;
if (!isNull _btnA) then {
    _btnA setVariable [QGVAR(disp), _display];
    if (!_isAmmo && {_sideLock > -1}) then {
        _btnA ctrlEnable false;
    } else {
        _btnA ctrlAddEventHandler ["ButtonClick", {
            params ["_b"];
            private _disp = _b getVariable QGVAR(disp);
            private _opts = _disp getVariable [QGVAR(pickAOpts), []];
            _disp setVariable [QGVAR(pickAIdx), ((_disp getVariable [QGVAR(pickAIdx), 0]) + 1) mod (count _opts)];
            _disp setVariable [QGVAR(pickBIdx), 0];
            [_disp] call (_disp getVariable QGVAR(pickPopulate));
        }];
    };
};
private _btnB = _display controlsGroupCtrl 1211;
if (!isNull _btnB) then {
    _btnB setVariable [QGVAR(disp), _display];
    _btnB ctrlAddEventHandler ["ButtonClick", {
        params ["_b"];
        private _disp = _b getVariable QGVAR(disp);
        private _opts = _disp getVariable [QGVAR(pickBOpts), ["All"]];
        _disp setVariable [QGVAR(pickBIdx), ((_disp getVariable [QGVAR(pickBIdx), 0]) + 1) mod (count _opts)];
        [_disp] call (_disp getVariable QGVAR(pickPopulate));
    }];
};

// ---- the ticks -----------------------------------------------------------
_list setVariable [QGVAR(disp), _display];
_list ctrlAddEventHandler ["LBSelChanged", {
    params ["_lb"];
    private _disp = _lb getVariable QGVAR(disp);
    if (_disp getVariable [QGVAR(pickBusy), false]) exitWith {};
    private _sel = _disp getVariable [QGVAR(pickSel), []];
    if (_disp getVariable [QGVAR(pickSingle), false]) then {
        private _i = lbCurSel _lb;
        _sel = if (_i < 0) then {[]} else {[_lb lbData _i]};
    } else {
        private _ticked = lbSelection _lb;
        for "_i" from 0 to (lbSize _lb - 1) do {
            private _cn = _lb lbData _i;
            if (_cn isEqualTo "") then {continue};
            if (_i in _ticked) then { _sel pushBackUnique _cn } else { _sel = _sel - [_cn] };
        };
    };
    _disp setVariable [QGVAR(pickSel), _sel];
    [_disp] call (_disp getVariable QGVAR(pickTitle));
}];
