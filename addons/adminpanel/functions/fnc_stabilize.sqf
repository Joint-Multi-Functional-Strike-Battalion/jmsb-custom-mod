#include "script_component.hpp"
/*
 * Author: JMSB
 * STABILIZE (user, 2026-10-31: "a stable button above wake up, this
 * stabilizes the patient to the requirements of ACM for conversion"): the
 * selected man is brought to what ACM's casualty conversion asks of the
 * patient himself - not bleeding and, when ACM requires antibiotics, a dose
 * of Ertapenem in him (ACM_evacuation_fnc_canConvert). The request goes to
 * the server, which checks the admin and sends it on to where he is local
 * (FUNC(stabilizeLocal), review S7); the answer comes back as a notification. He is neither woken nor healed, and
 * the medic's side of the rule - skill, place, tickets - is not touched.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_stabilize
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

private _patient = [_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX] call admp_fnc_playerFromSelection;

private _refused = switch (true) do {
    case (isNull _patient): {"No target found!"};
    case (!isClass (configFile >> "CfgPatches" >> ACM_PATCH)): {"ACM is not loaded - nothing to stabilize for."};
    case (!alive _patient): {format ["%1 is dead!", name _patient]};
    default {""};
};
if (_refused isNotEqualTo "") exitWith {
    ["Admin Panel", _refused, NOTE_FAIL] call EFUNC(notify,notify);
    playSound "addItemFailed";
};

[_patient] remoteExecCall [QFUNC(stabilizeLocal), ADMIN_SERVER];
playSound "3DEN_notificationDefault";
