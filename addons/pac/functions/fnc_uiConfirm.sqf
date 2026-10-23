#include "script_component.hpp"
/*
    File: fnc_uiConfirm.sqf
    Author: YonV
    Description: "Are you sure?" - a box over the page with the question,
        YES in red and NO. Every delete on the website asks first, so every
        delete here asks first, in the same words.

    Parameters:
        0: The question <STRING>
        1: What to do on YES <CODE> - called with the argument as _this
        2: An argument for it <ANY> (optional) - a code block written on a
           page cannot see the page's locals when it runs later, so what it
           needs is handed over here

    Returns:
        Nothing
*/

params [["_text", "", [""]], ["_code", {}, [{}]], ["_arg", []]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

GVAR(uiConfirmCode) = _code;
GVAR(uiConfirmArg) = _arg;
([PAC_IDC_CONFIRM_TEXT] call FUNC(uiCtrl)) ctrlSetStructuredText parseText format [
    "<t color='#e4574a'>ARE YOU SURE?</t><br/><br/>%1", [_text] call FUNC(uiEsc)
];
{([_x] call FUNC(uiCtrl)) ctrlShow true} forEach [
    PAC_IDC_CONFIRM_DIM, PAC_IDC_CONFIRM_BOX, PAC_IDC_CONFIRM_TEXT, PAC_IDC_CONFIRM_YES, PAC_IDC_CONFIRM_NO
];
