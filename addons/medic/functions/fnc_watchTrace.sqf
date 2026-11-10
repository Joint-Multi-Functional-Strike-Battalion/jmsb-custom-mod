#include "script_component.hpp"
/*
 * Author: YonV
 * What the watch HUD's EKG trace draws for one patient (user, 2026-11-08:
 * "make this fancier with maybe a ekg"; jmfsb_watch_fnc_trace). THE TABLET IS
 * AN EKG (user, 2026-10-22), so the rate and rhythm are live on every man ACE
 * medical has set up: ACE's heart rate, and ACM's cardiac rhythm when ACM is
 * loaded. A dead man, asystole, or no rate is a flat line. Each man has his
 * own phase (the seed), and the pleth his pulse strength.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * [beats per minute, rhythm - "sinus", "pea", "vt", "vf" or "flat", seed 0-1,
 * pulse 0-1] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_watchTrace
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

// HIS OWN TRACE (user, 2026-11-08: "looks the same on every one"): a phase
// and R height kept on the man for this machine, and his pulse strength -
// the pulse pressure over TRACE_PULSE_FULL mmHg - for the pleth.
private _seed = _unit getVariable [QGVAR(traceSeed), -1];
if (_seed < 0) then {
    _seed = random 1;
    _unit setVariable [QGVAR(traceSeed), _seed];
};
if (isNull _unit || {!alive _unit}) exitWith {[0, "flat", _seed, 0]};
private _hr = _unit getVariable [ACEV_HEART_RATE, 0];
private _rhythm = if (GVAR(acm)) then {_unit getVariable [ACMV_RHYTHM, RHYTHM_SINUS]} else {RHYTHM_SINUS};
if !(_rhythm isEqualType 0) then {_rhythm = RHYTHM_SINUS};
(_unit getVariable [ACEV_BLOOD_PRESSURE, [0, 0]]) params [["_dia", 0], ["_sys", 0]];
private _pulse = [0, ((_sys - _dia) / TRACE_PULSE_FULL) min 1] select (_hr > 0 && {!(_unit getVariable [ACEV_CARDIAC_ARREST, false])});

// RHYTHMS: sinus, asystole, VF, pulseless VT, VT, PEA
private _kind = TRACE_KINDS param [_rhythm, "flat"];
if (_kind isEqualTo "pea") exitWith {[PEA_TRACE_RATE, _kind, _seed, 0]};
if (_kind isEqualTo "sinus" && _hr <= 0) then {_kind = "flat"};
[_hr, _kind, _seed, _pulse]
