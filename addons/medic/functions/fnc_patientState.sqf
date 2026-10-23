#include "script_component.hpp"
/*
 * Author: JMSB
 * What state a man is in, as a medic sorts him: ARREST, UNCONSCIOUS, WOUNDED,
 * OK or DEAD, with how hard he is bleeding and how many open wounds he has.
 *
 * READS ONLY WHAT ACE PUBLISHES. Cardiac arrest, unconsciousness, the wound
 * bleed rate, open wounds, fractures, the in-pain flag and hemorrhage class are
 * all set public by ACE on the patient's own machine, so this answers the same
 * for a man across the map as for the man beside you. The pain LEVEL is local,
 * so it only counts for a local man. The bleed grade uses ACE's blood loss and
 * cardiac output, which are worked out from the synced vitals - a few seconds
 * stale on a remote unit, never wrong in kind.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * 0: State, STATE_ARREST .. STATE_DEAD <NUMBER>
 * 1: Bleeding heavily (SEVERE or MASSIVE) <BOOL>
 * 2: Bleed grade, -1 none, else an index into BLEED_WORDS <NUMBER>
 * 3: Open wounds <NUMBER>
 *
 * Example:
 * ([_unit] call jmfsb_medic_fnc_patientState) params ["_state", "_heavy", "_grade", "_wounds"]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit}) exitWith {[STATE_DEAD, false, -1, 0]};

// --- bleeding, graded the way ACE's medical menu grades it --------------------
// The BLOOD LOSS rate (wound bleeding x cardiac output x bleeding coefficient)
// against the knock-out rate - not the raw wound bleeding, which is a fraction
// of cardiac output and would put every threshold about ten times too low.
// ACM overrides ace_medical_status_fnc_getBloodLoss, so with ACM loaded this
// is ACM's own grade (ACM_core_fnc_getBleedSeverity).
private _bleed = _unit getVariable [ACEV_WOUND_BLEEDING, 0];
if !(_bleed isEqualType 0) then {_bleed = 0};

private _grade = -1;
if (_bleed > 0) then {
    private _output = CARDIAC_OUTPUT_NOMINAL;
    if (!isNil "ace_medical_status_fnc_getCardiacOutput") then {
        _output = [_unit] call ace_medical_status_fnc_getCardiacOutput;
    };
    private _loss = if (!isNil "ace_medical_status_fnc_getBloodLoss") then {
        [_unit] call ace_medical_status_fnc_getBloodLoss
    } else {
        _bleed * (_output max CARDIAC_OUTPUT_FLOOR) * (missionNamespace getVariable [ACEV_BLEEDING_COEF, 1])
    };
    private _knockout = BLEED_KNOCKOUT * (_output max CARDIAC_OUTPUT_FLOOR);
    _grade = BLEED_STEPS findIf {_loss < _knockout * _x};
    if (_grade < 0) then {_grade = count BLEED_STEPS};
};

// --- open wounds: a hashmap of part -> wounds since ACE 3.16, a flat array before
private _open = _unit getVariable [ACEV_OPEN_WOUNDS, createHashMap];
private _wounds = 0;
if (_open isEqualType createHashMap) then {
    {
        {_wounds = _wounds + ceil (_x param [1, 0])} forEach _y;
    } forEach _open;
} else {
    if (_open isEqualType []) then {
        {_wounds = _wounds + ceil (_x param [2, 0])} forEach _open;
    };
};

// --- the state ------------------------------------------------------------------
private _fractures = _unit getVariable [ACEV_FRACTURES, []];
private _hurt = _wounds > 0
    || _bleed > 0
    || {(_unit getVariable [ACEV_HEMORRHAGE, 0]) > 0}
    || {(_unit getVariable [ACEV_IN_PAIN, false]) isEqualTo true}
    || {local _unit && {(_unit getVariable [ACEV_PAIN, 0]) >= (PAIN_STEPS select 0)}}
    || {(_fractures isEqualType []) && {(_fractures findIf {_x isEqualTo 1}) > -1}};

private _state = switch (true) do {
    case (_unit getVariable [ACEV_CARDIAC_ARREST, false]): {STATE_ARREST};
    case ((_unit getVariable [ACEV_UNCONSCIOUS, false]) || {lifeState _unit isEqualTo "INCAPACITATED"}): {STATE_UNCON};
    case (_hurt): {STATE_WOUNDED};
    default {STATE_OK};
};

[_state, _grade >= BLEED_HEAVY, _grade, _wounds]
