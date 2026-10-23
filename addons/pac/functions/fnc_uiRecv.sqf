#include "script_component.hpp"
/*
    File: fnc_uiRecv.sqf
    Author: YonV
    Description: The server's answer to FUNC(uiAsk) lands here: the payload
        is kept under its name in GVAR(uiData), and the page is redrawn if
        it was waiting for exactly this.

    Parameters:
        0: What <STRING> - the name it was asked by
        1: The payload <ANY>

    Returns:
        Nothing
*/

params [["_what", "", [""]], "_payload"];

if (!hasInterface || _what isEqualTo "") exitWith {};
if (isNil QGVAR(uiData)) then {GVAR(uiData) = createHashMap};
GVAR(uiData) set [_what, _payload];

disableSerialization;
// The shell, not the display: inside the tablet the display is the device,
// which outlives the page (FUNC(uiHost)); the shell goes with the page.
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};
if (_what in (missionNamespace getVariable [QGVAR(uiWaiting), []])) then {
    [] call FUNC(uiDraw);
};
