#include "script_component.hpp"
/*
    File: fnc_pgWindowStart.sqf
    Author: YonV
    Description: Start a window - a name, what kind it is, and START.
        Attendance counts against it until an admin stops it on the
        dashboard. Only an Operation counts toward promotion as an op;
        Training has its own weights; Special counts for nothing.

    Parameters:
        None

    Returns:
        Nothing
*/

["Start a window", "Dashboard"] call FUNC(uiTitle);

private _y = [[
    ["name", "Name", "t", ""],
    ["kind", "Kind", "c", "operation", [["operation", "Operation - counts toward promotion"], ["training", "Training - training time"], ["special", "Special - not counted"]]]
], PAC_UI_TOP] call FUNC(uiForm);
["A window is what attendance is counted against. Only an Operation counts toward promotion; Training counts as training time; Special counts for nothing. It stays open across a server restart; stop it on the dashboard when it is over.", _y + 0.006, 0.08, "", PAC_UI_X, PAC_UI_W, true] call FUNC(uiText);

[[
    ["START", {
        private _f = [] call FUNC(uiFormRead);
        private _name = trim (_f getOrDefault ["name", ""]);
        if (_name isEqualTo "") exitWith {["Give the window a name.", true] call FUNC(uiHint)};
        [player, "start", _name, _f getOrDefault ["kind", "operation"]] remoteExec [QFUNC(windowSet), 2];
        [] call FUNC(uiBack);
    }]
]] call FUNC(uiButtons);
