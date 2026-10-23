#include "script_component.hpp"
/*
    File: fnc_uiPlace.sqf
    Author: YonV
    Description: Put a control somewhere and show it. Positions are
        fractions of the shell group (ui/pac.inc.hpp, GVAR(shell)) - the same
        numbers the config is written in. In the dialog the shell is the whole
        safe zone, so a fraction is what it always was; inside the tablet it
        is the tablet's map area (FUNC(uiHost)), and the page lays itself out
        in that instead.

    Parameters:
        0: The control, or its idc <CONTROL|NUMBER>
        1: x <NUMBER>
        2: y <NUMBER>
        3: w <NUMBER>
        4: h <NUMBER>

    Returns:
        The control <CONTROL>
*/

params ["_ctrl", ["_x", 0, [0]], ["_y", 0, [0]], ["_w", 0, [0]], ["_h", 0, [0]]];

disableSerialization;
if (_ctrl isEqualType 0) then {
    _ctrl = [_ctrl] call FUNC(uiCtrl);
};
if (isNull _ctrl) exitWith {controlNull};

// A child's position is relative to its group, so the group's own size is all
// that is needed.
(ctrlPosition (uiNamespace getVariable [QGVAR(shell), controlNull])) params ["", "", ["_gw", safeZoneW], ["_gh", safeZoneH]];
_ctrl ctrlSetPosition [_x * _gw, _y * _gh, _w * _gw, _h * _gh];
_ctrl ctrlCommit 0;
_ctrl ctrlShow true;
_ctrl
