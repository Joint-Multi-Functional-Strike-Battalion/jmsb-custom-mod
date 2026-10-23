#include "script_component.hpp"
/*
    File: fnc_uiTitle.sqf
    Author: YonV
    Description: The page title (the website's <h1>) and the line under the
        bar that says where you are - the website's "&larr; Roster · doc id"
        line, in grey.

    Parameters:
        0: Title <STRING>
        1: The where-you-are line <STRING> (optional)

    Returns:
        Nothing
*/

params [["_title", "", [""]], ["_crumb", "", [""]]];

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

([PAC_IDC_PAGE_TITLE] call FUNC(uiCtrl)) ctrlSetStructuredText parseText format [
    "<t size='0.85' font='RobotoCondensedBold'>%1</t>", [_title] call FUNC(uiEsc)
];
([PAC_IDC_CRUMB] call FUNC(uiCtrl)) ctrlSetStructuredText parseText format [
    "<t color='#8b97a3'>%1</t>", [_crumb] call FUNC(uiEsc)
];
