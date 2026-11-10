#include "script_component.hpp"
/*
 * Author: YonV
 * COPY, under the return box: the whole return, every line, onto the
 * clipboard (user, 2026-09-05: "add a copy button to copy the return"). A
 * value you can only read off a listbox is a value you end up retyping.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_execCopy
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

private _list = _display displayCtrl IDC_ADMINPANEL_REMOTEEXEC_RETURN;
private _lines = [];
for "_i" from 0 to (lbSize _list) - 1 do {
    _lines pushBack (_list lbText _i);
};

private _fnc_tell = {
    params ["_text", "_bad"];
    if (isNil "jmfsb_notify_fnc_notify") exitWith {};
    ["TAC//ADMIN", _text, [[0.4, 0.702, 0.4, 1], [0.831, 0.267, 0.267, 1]] select _bad] call jmfsb_notify_fnc_notify;
};

if (_lines isEqualTo []) exitWith {
    ["Nothing to copy - run something first.", true] call _fnc_tell;
};

copyToClipboard (_lines joinString endl);
[format ["Return copied - %1 line(s).", count _lines], false] call _fnc_tell;
