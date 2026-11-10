#include "script_component.hpp"
/*
 * Author: YonV
 * END MISSION, armed on the first press and fired on the second.
 *
 * THE ONE BUTTON ON THIS SCREEN THAT ENDS EVERYBODY'S EVENING. The mission panel
 * had this block commented out entirely - its button shared an idc with HEAL ALL
 * - so nobody has pressed it in anger yet, which makes now the time to decide how
 * hard it should be to press by accident.
 *
 * Two stages, which is what the design's CONFIRM x2 means: the first press arms
 * the button and it says so, and the second inside ten seconds hands off to the
 * panel's own admp_fnc_endMission - which puts up its own are-you-sure naming
 * the ending. Walk away and it disarms itself.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_confirmEnd
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

private _button = _display displayCtrl IDC_ADMINPANEL_MISSION_ENDBUTTON;
if (isNull _button) exitWith {};

private _armedAt = missionNamespace getVariable [QGVAR(endArmedAt), -1e9];

if (CBA_missionTime - _armedAt <= 10) exitWith {
    GVAR(endArmedAt) = -1e9;
    _button ctrlSetText "END MISSION";
    [] spawn admp_fnc_endMission;
};

GVAR(endArmedAt) = CBA_missionTime;
_button ctrlSetText "PRESS AGAIN TO END";

// Disarmed by the clock, not by another press. A button left saying PRESS AGAIN
// TO END for the rest of the session is a trap.
[{
    params ["_display"];

    if (isNull _display) exitWith {};
    if (CBA_missionTime - (missionNamespace getVariable [QGVAR(endArmedAt), -1e9]) < 10) exitWith {};

    private _button = _display displayCtrl IDC_ADMINPANEL_MISSION_ENDBUTTON;
    if (!isNull _button) then {_button ctrlSetText "END MISSION"};
}, [_display], 10] call CBA_fnc_waitAndExecute;
