#include "script_component.hpp"
/*
    File: fnc_pgArsenalList.sqf
    Author: YonV
    Description: One arsenal list - its name and the classnames, one per
        line, SAVE and DELETE. Paste from a .hpp; commas, quotes and braces
        are stripped on save.

    Parameters:
        None - reads GVAR(uiArgs): v, name ("" = new)

    Returns:
        Nothing
*/

private _v = GVAR(uiArgs) getOrDefault ["v", ""];
private _name = GVAR(uiArgs) getOrDefault ["name", ""];
private _new = _name isEqualTo "";
private _unit = GVAR(settings) getOrDefault ["unitId", ""];
private _ars = GVAR(structure) getOrDefault ["arsenal", createHashMap];
private _lists = if (_v isEqualTo "") then {_ars getOrDefault ["lists", createHashMap]} else {
    (_ars getOrDefault ["variants", createHashMap]) getOrDefault [_v, createHashMap]
};
if !(_lists isEqualType createHashMap) then {_lists = createHashMap};
private _classes = _lists getOrDefault [_name, []];
if !(_classes isEqualType []) then {_classes = []};

[[_name, "New list"] select _new, format ["Templates  -  Common arsenal  -  %1.arsenal%2", _unit, ["", "." + _v] select (_v isNotEqualTo "")]] call FUNC(uiTitle);

private _y = [[["name", "List", ["r", "t"] select _new, _name]], PAC_UI_TOP] call FUNC(uiForm);

disableSerialization;
private _head = [PAC_IDC_BIGEDIT_HEAD, PAC_UI_X, _y, PAC_UI_W, 0.026] call FUNC(uiPlace);
_head ctrlSetStructuredText parseText format ["<t color='#93cf72' size='0.7'>CLASSNAMES  %1  -  one per line</t>", count _classes];
private _edit = [PAC_IDC_BIGEDIT, PAC_UI_X, _y + 0.028, PAC_UI_W, PAC_UI_BOTTOM - _y - 0.028] call FUNC(uiPlace);
_edit ctrlSetText ((_classes apply {if (_x isEqualType "") then {_x} else {str _x}}) joinString (toString [10]));

private _btns = [
    ["SAVE", {
        disableSerialization;
        private _f = [] call FUNC(uiFormRead);
        private _name = trim (_f getOrDefault ["name", ""]);
        if (_name isEqualTo "") exitWith {["The list needs a name.", true] call FUNC(uiHint)};
        private _text = ctrlText ([PAC_IDC_BIGEDIT] call FUNC(uiCtrl));
        {_text = [_text, _x, " "] call CBA_fnc_replace} forEach [",", ";", "{", "}", "[", "]", toString [34], "'"];
        private _classes = ((_text splitString (toString [10] + " " + toString [13] + toString [9])) apply {trim _x}) select {_x isNotEqualTo ""};
        private _rec = createHashMapFromArray [["classes", _classes], ["variant", GVAR(uiArgs) getOrDefault ["v", ""]]];
        [player, "arsenal", "set", _name, _rec] remoteExec [QFUNC(adminStructure), 2];
        [] call FUNC(uiBack);
    }]
];
if (!_new) then {
    _btns pushBack ["DELETE", {
        [format ["Delete the list %1?", GVAR(uiArgs) getOrDefault ["name", ""]], {
            [player, "arsenal", "remove", GVAR(uiArgs) getOrDefault ["name", ""], createHashMapFromArray [["variant", GVAR(uiArgs) getOrDefault ["v", ""]]]] remoteExec [QFUNC(adminStructure), 2];
            [] call FUNC(uiBack);
        }] call FUNC(uiConfirm);
    }, true];
};
[_btns] call FUNC(uiButtons);
