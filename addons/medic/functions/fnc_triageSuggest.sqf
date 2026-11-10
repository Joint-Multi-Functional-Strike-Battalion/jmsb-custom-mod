#include "script_component.hpp"
/*
 * Author: YonV
 * The triage the watch HUD suggests from a patient's state (design medical:
 * "auto-suggested from vitals; medic override sticks until changed" - the
 * override is ACE's own triage card). The unit's ACM board's categories:
 *
 *     T1 immediate  cardiac arrest, unconscious, or bleeding heavily
 *     T2 delayed    bleeding, or SpO2 under SPO2_ALERT
 *     T3 minimal    wounded otherwise
 *     T4 expectant  dead
 *     0             nothing wrong
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * Triage 0-4 <NUMBER>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_triageSuggest
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

([_unit] call FUNC(patientState)) params ["_state", "_heavy", "_grade"];
switch (true) do {
    case (_state isEqualTo STATE_DEAD): {4};
    case (_state in [STATE_ARREST, STATE_UNCON] || _heavy): {1};
    case (_grade > -1 || {(_unit getVariable [ACEV_SPO2, SPO2_FULL]) < SPO2_ALERT}): {2};
    case (_state isEqualTo STATE_WOUNDED): {3};
    default {0};
}
