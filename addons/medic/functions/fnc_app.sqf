#include "script_component.hpp"
/*
 * Author: JMSB
 * TAC//MEDIC - the squad as a medic triages it. Two pages in one frame: the
 * PATIENT LIST (the player's group, worst first) and a PATIENT's own page
 * (vitals, blood, airway, chest, wounds, tourniquets, splints, IVs, and SHOW
 * ON MAP). Pressing a patient opens his page; BACK returns to the list.
 *
 * FOR A CLS OR A MEDIC (FUNC(isMedic)). The tile is only drawn for one, so
 * nobody else reaches this; the gate is repeated here so an app opened some
 * other way says who it is for rather than showing a stranger's vitals.
 *
 * WITHOUT ACE MEDICAL it loads, opens and says MEDICAL SYSTEM NOT LOADED.
 * Without ACM it runs on ACE alone and the ACM-only lines say so.
 *
 * IT REDRAWS ITSELF every MEDIC_REFRESH seconds while open, through the same
 * appAlive / appIdle pair every live app uses, so a press is never deleted
 * from under the cursor.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["medic", [], true] call jmfsb_tacpad_fnc_openApp
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

// A FRESH OPEN STARTS ON THE LIST. A redraw - the refresh loop, a press inside
// the app - finds the group this addon drew still standing; anything else is
// the tile. The tile may be alerting about someone other than the man whose
// page was open an hour ago, so a fresh open goes to the list, except straight
// after SHOW ON MAP (GVAR(keepPatient)) - and even then not when someone else
// is in arrest or bleeding heavily.
private _currentGroup = uiNamespace getVariable [QEGVAR(tacpad,appGroup), controlNull];
private _fresh = isNull _currentGroup || _currentGroup isNotEqualTo (uiNamespace getVariable [QGVAR(group), controlNull]);
if (_fresh && {!isNull GVAR(patient)}) then {
    private _others = (units group player) - [GVAR(patient)];
    private _keep = GVAR(keepPatient) && {
        (_others findIf {
            ([_x] call FUNC(patientState)) params ["_state", "_heavy"];
            _state isEqualTo STATE_ARREST || _heavy
        }) < 0
    };
    if (!_keep) then {GVAR(patient) = objNull};
};
GVAR(keepPatient) = false;

// A patient who has left the section, or been deleted, drops the page back to
// the list rather than showing a man the medic no longer has.
private _patient = GVAR(patient);
if (!isNull _patient && {!(_patient in units group player)}) then {
    GVAR(patient) = objNull;
    _patient = objNull;
};

private _medic = [player] call FUNC(isMedic);
private _live = _medic && GVAR(ace);
private _paged = _live && {!isNull _patient};

private _title = ["MEDIC - SQUAD CASUALTIES", format ["MEDIC - %1", toUpper ([_patient] call FUNC(nameOf))]] select _paged;
([_display, _title, APP_W, APP_H] call EFUNC(tacpad,appFrame)) params ["_group", "_body"];
// A CONTROL LIVES IN uiNamespace. Kept in the mission namespace it made the
// engine warn on every save that the variable cannot be serialised (RPT
// 2026-10-20), and a control means nothing to a saved mission anyway.
uiNamespace setVariable [QGVAR(group), _group];
if (isNull _body) exitWith {};

switch (true) do {
    case (!_medic): {
        [_body, "CLS OR MEDIC ONLY", "THIS PAGE IS FOR A PLAYER WHOSE PAC SKILLS INCLUDE CLS OR MEDIC"] call FUNC(appNotice);
    };
    case (!GVAR(ace)): {
        [_body, "MEDICAL SYSTEM NOT LOADED", "ACE MEDICAL IS NOT RUNNING - THERE IS NOTHING TO READ"] call FUNC(appNotice);
    };
    case (_paged): {[_body, _patient] call FUNC(appPatient)};
    default {[_body] call FUNC(appList)};
};

// A notice does not change; only a live page needs the loop. The handle is a
// mission variable: a CBA handler id means nothing in the next mission, and a
// stale one kept in uiNamespace would remove somebody else's handler there.
if (GVAR(pfh) >= 0) then {
    [GVAR(pfh)] call CBA_fnc_removePerFrameHandler;
    GVAR(pfh) = -1;
};
if (!_live) exitWith {};

GVAR(pfh) = [{
    params ["", "_handle"];

    // Alive decides whether the loop lives; idle decides whether it may redraw
    // - see EFUNC(tacpad,appIdle).
    if !([APP_ID] call EFUNC(tacpad,appAlive)) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        GVAR(pfh) = -1;
    };

    if !([] call EFUNC(tacpad,appIdle)) exitWith {};
    [APP_ID] call EFUNC(tacpad,openApp);
}, MEDIC_REFRESH, []] call CBA_fnc_addPerFrameHandler;
