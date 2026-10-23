#include "script_component.hpp"
/*
    File: fnc_uiLoaded.sqf
    Author: YonV
    Description: The dialog's onLoad - the bar's fixed text, then the first
        page. Everything a page draws is drawn by FUNC(uiDraw).

    Parameters:
        None

    Returns:
        Nothing
*/

disableSerialization;

if (isNull (uiNamespace getVariable [QGVAR(shell), controlNull])) exitWith {};

private _unit = GVAR(settings) getOrDefault ["unitId", ""];
([PAC_IDC_UNIT] call FUNC(uiCtrl)) ctrlSetText ([_unit, "  -  no unit id"] select (_unit isEqualTo ""));
([PAC_IDC_WHO] call FUNC(uiCtrl)) ctrlSetText format ["%1  %2", name player, [player] call FUNC(uid)];

GVAR(uiFilterText) = "";
GVAR(uiFilling) = false;
GVAR(uiConfirmCode) = {};
if (isNil QGVAR(uiData)) then {GVAR(uiData) = createHashMap};
if (isNil QGVAR(uiHistory)) then {GVAR(uiHistory) = []};
if (isNil QGVAR(uiPage)) then {GVAR(uiPage) = "dashboard"};
if (isNil QGVAR(uiArgs)) then {GVAR(uiArgs) = createHashMap};

[GVAR(uiPage), GVAR(uiArgs)] call FUNC(uiGo);
