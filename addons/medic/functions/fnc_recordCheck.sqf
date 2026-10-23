#include "script_component.hpp"
/*
 * Author: JMSB
 * A medic finished a hand check on somebody: ask the patient's machine to take
 * the reading. Hooked to ACE's ace_treatmentSucceded, which fires on the
 * medic's own machine.
 *
 * WHICH CHECKS. A pulse check gives a heart rate, ACE's own blood pressure
 * check gives a blood pressure, and ACM's Check Breathing gives a respiration
 * rate. With ACM loaded, CheckBloodPressure is its capillary refill - it
 * measures no pressure, so it records none.
 *
 * ACM's cuff readings (MeasureBloodPressure, ...Stethoscope) record nothing
 * either. Their treatment finishes in a hundredth of a second and only opens
 * ACM's gauge, which the medic may cancel - so the "success" comes before any
 * reading exists. They need the cuff on the arm, and while it is the BP line
 * is live anyway (FUNC(readVitals)).
 *
 * NOT READ HERE. A remote patient's vitals on this machine are the last values
 * his owner synced, up to twenty seconds old - so the reading is taken on the
 * patient's machine, where they are exact, and published from there. See
 * FUNC(measureLocal).
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 * 2: Body part <STRING>
 * 3: Treatment class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorObject, "leftarm", "CheckPulse"] call jmfsb_medic_fnc_recordCheck
 *
 * Public: No
 */

params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]], ["_bodyPart", "", [""]], ["_classname", "", [""]]];

if (isNull _patient || {!local _medic}) exitWith {};

private _kind = switch (true) do {
    case (_classname isEqualTo CHECK_PULSE): {"hr"};
    case (_classname isEqualTo CHECK_BP_ACE && {!GVAR(acm)}): {"bp"};
    case (_classname isEqualTo CHECK_BREATHING): {"rr"};
    default {""};
};

if (_kind isEqualTo "") exitWith {};

[QGVAR(measure), [_patient, _kind, toLowerANSI _bodyPart, name _medic], _patient] call CBA_fnc_targetEvent;
