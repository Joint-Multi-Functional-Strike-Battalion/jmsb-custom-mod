#include "script_component.hpp"
/*
 * Author: JMSB
 * STABILIZE's work (FUNC(stabilize)). Sent to the server, which checks the
 * sender is an admin by its own records and names him the admin, then sends
 * it on to the machine where the patient's medical state is local; that
 * machine takes it only from the server (review S7). What ACM's casualty
 * conversion asks of him (ACM_evacuation_fnc_canConvert), done there:
 * - BLEEDING: every body part bandaged, pass after pass, until ACE's wound
 *   bleeding is nil - ACM's pressure bandage (ACE's field dressing without
 *   ACM). Plain bandages, so a wound can reopen later as ACM's do.
 * - ANTIBIOTICS, when ACM's Require antibiotics setting is on: 1 g of
 *   Ertapenem IV through ACM's medicationLocal, on his triage card and log,
 *   unless that much is in him already.
 * Nothing wakes or heals him. The admin is told what was done, in red when
 * he still bleeds, and that a conscious man is not a casualty ACM converts.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Admin who pressed it - set by the server, never by the sender <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorTarget] remoteExecCall ["jmfsb_adminpanel_fnc_stabilizeLocal", 2]
 *
 * Public: No
 */

params [["_patient", objNull, [objNull]], ["_admin", objNull, [objNull]]];

if (isServer) then {
    if !([] call EFUNC(common,senderIsAdmin)) exitWith {_patient = objNull};
    _admin = ([] call EFUNC(common,sender)) select 1;
} else {
    if !([] call EFUNC(common,fromServer)) then {_patient = objNull};
};
if (isNull _patient || {!alive _patient}) exitWith {};
if (!local _patient) exitWith {
    // The answer comes back by FUNC(stabilizeDone), which tells only the
    // admin kept here, for this patient (review R1).
    private _pending = localNamespace getVariable [QGVAR(stabilizePending), createHashMap];
    _pending set [netId _patient, [_admin, CBA_missionTime + STABLE_ANSWER_S]];
    localNamespace setVariable [QGVAR(stabilizePending), _pending];
    [_patient, _admin] remoteExecCall [QFUNC(stabilizeLocal), _patient];
};

private _done = [];
private _failed = false;

// bleeding
if ((_patient getVariable [ACE_VAR_BLEEDING, 0]) > 0) then {
    private _bandage = [STABLE_BANDAGE_ACE, STABLE_BANDAGE_ACM] select isClass (configFile >> "ace_medical_treatment" >> "Bandaging" >> STABLE_BANDAGE_ACM);
    for "_pass" from 1 to STABLE_BANDAGE_PASSES do {
        {
            [_patient, _x, _bandage] call ace_medical_treatment_fnc_bandageLocal;
        } forEach STABLE_BODY_PARTS;
        if ((_patient getVariable [ACE_VAR_BLEEDING, 0]) <= 0) exitWith {};
    };
    _failed = (_patient getVariable [ACE_VAR_BLEEDING, 0]) > 0;
    _done pushBack (["bleeding stopped", "STILL BLEEDING"] select _failed);
};

// antibiotics
if (missionNamespace getVariable [ACM_REQUIRE_ANTIBIOTICS, false]) then {
    private _inHim = ([_patient, STABLE_ERTAPENEM, true] call ace_medical_status_fnc_getMedicationCount)
        + ([_patient, STABLE_ERTAPENEM_IM, true] call ace_medical_status_fnc_getMedicationCount);
    if (_inHim < STABLE_ERTAPENEM_MIN) then {
        [_patient, STABLE_ERTAPENEM_PART, STABLE_ERTAPENEM, STABLE_ERTAPENEM_MG, true] call ace_medical_treatment_fnc_medicationLocal;
        [_patient, STABLE_ERTAPENEM_CARD] call ace_medical_treatment_fnc_addToTriageCard;
        [_patient, "activity", "%1 gave %2", [[_admin, false, true] call ace_common_fnc_getName, STABLE_ERTAPENEM_CARD]] call ace_medical_treatment_fnc_addToLog;
        _done pushBack "Ertapenem 1 g IV given";
    };
};

private _said = if (_done isEqualTo []) then {
    format ["%1 already meets what ACM's conversion needs of him", name _patient]
} else {
    format ["%1: %2", name _patient, _done joinString ", "]
};
if (!(_patient getVariable [ACE_VAR_UNCONSCIOUS, false])) then {
    _said = _said + " - conscious, and ACM converts unconscious casualties only";
};
TRACE_3("stabilize",_patient,_done,_failed);

// The admin is told by the server (review R1: the notify post event is gone).
if (_admin isEqualTo player) exitWith {
    ["Admin Panel", _said, [NOTE_DONE, NOTE_FAIL] select _failed] call EFUNC(notify,notify);
};
if (isServer) exitWith {
    ["Admin Panel", _said, [NOTE_DONE, NOTE_FAIL] select _failed, _admin] call EFUNC(notify,broadcast);
};
[_patient, _said, _failed] remoteExecCall [QFUNC(stabilizeDone), SERVER_OWNER];
