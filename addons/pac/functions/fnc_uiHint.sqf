#include "script_component.hpp"
/*
    File: fnc_uiHint.sqf
    Author: YonV
    Description: The flash line above the actions row - the website's
        `.flash.good` / `.flash.bad`: green for "saved", red for "no".

    Parameters:
        0: Text <STRING> - "" clears it
        1: Bad <BOOL> (optional, default false)

    Returns:
        Nothing
*/

params [["_text", "", [""]], ["_bad", false, [false]]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

private _c = [PAC_IDC_HINT] call FUNC(uiCtrl);
if (_text isEqualTo "") exitWith {_c ctrlSetStructuredText parseText ""};
_c ctrlSetStructuredText parseText format [
    "<t color='%1'>%2</t>", ["#93cf72", "#e4574a"] select _bad, [_text] call FUNC(uiEsc)
];
