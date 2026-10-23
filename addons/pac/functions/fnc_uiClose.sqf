#include "script_component.hpp"
/*
    File: fnc_uiClose.sqf
    Author: YonV
    Description: CLOSE on the bar. In the dialog it closes the dialog, as it
        always did. Inside the tablet the page is the tablet's open app
        (FUNC(uiHost)) and closes as every app there does - the shell goes,
        the tablet stays. It is a frame late there, because CLOSE is one of
        the controls the close deletes.

    Parameters:
        None

    Returns:
        Nothing
*/

disableSerialization;
private _shell = uiNamespace getVariable [QGVAR(shell), controlNull];
if (isNull _shell) exitWith {};

if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo PAC_APP) exitWith {
    [{
        if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo PAC_APP) then {
            [] call EFUNC(tacpad,appClose);
        };
    }] call CBA_fnc_execNextFrame;
};

(ctrlParent _shell) closeDisplay 2;
