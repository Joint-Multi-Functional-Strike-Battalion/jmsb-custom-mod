#include "script_component.hpp"
/*
 * Author: YonV
 * Eden attributeSave handler for the class picker (jmfsb_ClassPick_*).
 *
 * The cumulative selection on the display, re-synced with the listbox for a
 * click still in flight, plus whatever was typed into the override field -
 * joined with commas, which is what every read site splits. Empty means what
 * it always meant: the module's own default.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Single select <BOOL>
 *
 * Return Value:
 * Comma-separated class names <STRING>
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull, controlNull]], ["_single", false, [false]]];
if (isNull _display) exitWith {""};

private _sel = _display getVariable [QGVAR(pickSel), []];
private _list = _display controlsGroupCtrl 100;
if (!isNull _list) then {
    if (_single) then {
        private _i = lbCurSel _list;
        if (_i > -1) then { _sel = [_list lbData _i] };
    } else {
        private _ticked = lbSelection _list;
        for "_i" from 0 to (lbSize _list - 1) do {
            private _cn = _list lbData _i;
            if (_cn isEqualTo "") then {continue};
            if (_i in _ticked) then { _sel pushBackUnique _cn } else { _sel = _sel - [_cn] };
        };
    };
};
private _edit = _display controlsGroupCtrl 102;
if (!isNull _edit) then {
    {
        private _t = trim _x;
        if (_t isNotEqualTo "") then { _sel pushBackUnique _t };
    } forEach ((ctrlText _edit) splitString ",");
};
if (_single && {count _sel > 1}) then { _sel = [_sel select 0] };

private _result = _sel joinString ",";
_display setVariable ["value", _result];
_result
