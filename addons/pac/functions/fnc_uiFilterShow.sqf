#include "script_component.hpp"
/*
    File: fnc_uiFilterShow.sqf
    Author: YonV
    Description: Offer the filter box on this page - the website's
        "Filter" form on the roles, squads and document lists - and hand
        back what is in it, lower-cased, for the page to match rows against.

    Parameters:
        None

    Returns:
        The filter text, lower case <STRING>
*/

disableSerialization;
if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {""};

GVAR(uiFilterable) = true;
private _f = [PAC_IDC_FILTER] call FUNC(uiCtrl);
[PAC_IDC_FILTER_LABEL, 0.720, 0.114, 0.080, 0.030] call FUNC(uiPlace);
[_f, 0.808, 0.114, 0.180, 0.030] call FUNC(uiPlace);
if ((ctrlText _f) isNotEqualTo GVAR(uiFilterText)) then {_f ctrlSetText GVAR(uiFilterText)};

toLower GVAR(uiFilterText)
