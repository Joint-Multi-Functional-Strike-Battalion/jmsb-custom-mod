#include "script_component.hpp"
/*
 * Author: YonV
 * Which form a card opens on (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09:
 * "a STD / SHORT switch on the composer; the default is a player setting";
 * user: "simple or real world templates" as a unit option in TAC//PAC,
 * default REAL WORLD). The player setting GVAR(composeShort):
 *
 *   UNIT         the unit's option in TAC//PAC - PAC_TEMPLATE_FORM_VAR,
 *                published by the pac addon: "simple" is SIMPLE, anything
 *                else (or nothing set) REAL WORLD
 *   REAL WORLD   the standard form
 *   SIMPLE       the short form
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Open on the SIMPLE (short) form <BOOL>
 *
 * Example:
 * GVAR(composeShortOn) = [] call jmfsb_tacpad_fnc_composeShortDefault
 *
 * Public: No
 */

private _form = GVAR(composeShort);
if !(_form isEqualType "") then {_form = FORM_UNIT};
if (_form isEqualTo FORM_UNIT) then {
    _form = missionNamespace getVariable [PAC_TEMPLATE_FORM_VAR, FORM_REAL];
    if !(_form isEqualType "") then {_form = FORM_REAL};
};
(toLower _form) isEqualTo FORM_SIMPLE
