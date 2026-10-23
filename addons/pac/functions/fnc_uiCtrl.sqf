#include "script_component.hpp"
/*
    File: fnc_uiCtrl.sqf
    Author: YonV
    Description: One of the page's controls, by idc. Every control of TAC//PAC
        is a child of the shell group (ui/pac.inc.hpp, GVAR(shell)) and is
        found through it, never through the display: inside the tablet the
        display is the device dialog, which has controls of its own under the
        same small numbers (its map is idc 51).

    Parameters:
        0: The idc <NUMBER>

    Returns:
        The control, or controlNull while the page is not open <CONTROL>
*/

params [["_idc", -1, [0]]];

disableSerialization;
(uiNamespace getVariable [QGVAR(shell), controlNull]) controlsGroupCtrl _idc
