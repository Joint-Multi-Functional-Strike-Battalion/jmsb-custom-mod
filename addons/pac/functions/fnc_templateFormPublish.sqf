#include "script_component.hpp"
/*
    File: fnc_templateFormPublish.sqf
    Author: YonV
    Description: Server - puts the unit's SIMPLE / REAL WORLD template setting
        (user, 2026-11-09: "add a option in the pac for simple or real world
        templates ... default us to real world") where every client reads it:
        GVAR(templateForm), public, TEMPLATE_FORM_REAL or TEMPLATE_FORM_SIMPLE.
        Anything else in the settings - nothing set, a typo in the database -
        is REAL WORLD. Called at the end of the boot and when an admin changes
        it (FUNC(adminSetting)): it takes effect at once, a card opened after
        it opens in the new view.

    Parameters:
        None

    Returns:
        The form published <STRING>
*/

if (!isServer) exitWith {""};

private _form = GVAR(settings) getOrDefault [TEMPLATE_FORM_KEY, TEMPLATE_FORM_REAL];
if !(_form in TEMPLATE_FORMS) then {_form = TEMPLATE_FORM_REAL};
missionNamespace setVariable [QGVAR(templateForm), _form, true];
_form
