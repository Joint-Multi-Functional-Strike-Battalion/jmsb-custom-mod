#include "script_component.hpp"
/*
    File: fnc_uiConfirmAnswer.sqf
    Author: YonV
    Description: YES or NO on the "are you sure" box. Hides the box; on YES
        runs what FUNC(uiConfirm) was given.

    Parameters:
        0: Yes <BOOL>

    Returns:
        Nothing
*/

params [["_yes", false, [false]]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

{([_x] call FUNC(uiCtrl)) ctrlShow false} forEach [
    PAC_IDC_CONFIRM_DIM, PAC_IDC_CONFIRM_BOX, PAC_IDC_CONFIRM_TEXT, PAC_IDC_CONFIRM_YES, PAC_IDC_CONFIRM_NO
];
private _code = GVAR(uiConfirmCode);
private _arg = missionNamespace getVariable [QGVAR(uiConfirmArg), []];
GVAR(uiConfirmCode) = {};
GVAR(uiConfirmArg) = [];
if (_yes && {_code isNotEqualTo {}}) then {_arg call _code};
