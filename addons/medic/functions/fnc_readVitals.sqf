#include "script_component.hpp"
/*
 * Author: JMSB
 * The four numbers a medic monitors - heart rate, blood pressure, SpO2 and
 * respiration rate - each as what is on the screen and where it came from.
 *
 * THE TABLET IS AN EKG AND A PULSE OXIMETER (user, 2026-10-22), so heart
 * rate and SpO2 are LIVE on every man ACE medical has set up; the rest are
 * device-gated (user, 2026-10-19), LIVE only while a device that reads them
 * is on the patient, and a placed device wins over the tablet's leads:
 *
 *   HEART RATE   ACM's pulse oximeter, on either arm; else the tablet (ACE)
 *   SPO2         ACM's pulse oximeter, or the AED's pulse oximeter lead;
 *                else the tablet (ACE)
 *   BP           ACM's pressure cuff (the synced ACE value), or the AED's
 *                NIBP cuff (its last cycle)
 *   RESP RATE    the AED's capnograph
 *
 * Otherwise the line shows the last reading a medic took by hand - see
 * FUNC(recordCheck) - with its age and who took it; and with neither, "--" and
 * NOT MONITORED. There is no hand check for SpO2. A dead man's lines are all
 * "--" and DEAD.
 *
 * With a pulse oximeter on each arm, the one that has a reading is used - an
 * arm under a tourniquet reads nothing while the other one still does.
 *
 * Every source here is published by its owner: the ACM device displays and
 * placements are set public on the patient's machine, the cuff reads ACE's
 * blood pressure which ACE syncs every ten to twenty seconds, and the hand
 * readings are this addon's own public variables.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Four entries, HR / BP / SpO2 / RR, each [label, value, unit, source, live] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_readVitals
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _acm = GVAR(acm);
private _alive = alive _unit;

// The arm a pulse oximeter / cuff sits on, -1 for none. ACM's arrays are the
// two arms, left then right.
private _oxArm = -1;
private _cuffArm = -1;
private _aedOx = -1;
private _aedCuff = -1;
private _capno = false;
if (_acm && _alive) then {
    private _placed = _unit getVariable [ACMV_PULSEOX, [false, false]];
    private _shown = _unit getVariable [ACMV_PULSEOX_DISPLAY, [[0, 0], [0, 0]]];
    _oxArm = [0, 1] findIf {
        (_placed param [_x, false]) isEqualTo true && {((_shown param [_x, [0, 0]]) param [1, 0]) > 0}
    };
    if (_oxArm < 0) then {_oxArm = _placed find true};
    _cuffArm = (_unit getVariable [ACMV_CUFF, [false, false]]) find true;
    _aedOx = _unit getVariable [ACMV_AED_PULSEOX, -1];
    _aedCuff = _unit getVariable [ACMV_AED_CUFF, -1];
    _capno = _unit getVariable [ACMV_AED_CAPNO, false];
};
private _oxShown = (_unit getVariable [ACMV_PULSEOX_DISPLAY, [[0, 0], [0, 0]]]) param [_oxArm max 0, [0, 0]];

// Every line is [value, source, live]. Live is true only for a device that
// has produced a reading - it is never worked out from the source text, which
// for a hand check ends in the medic's name.
//
// The last hand reading of a kind - or "--" when nobody has taken one.
private _fnc_manual = {
    params ["_slot", "_format"];
    private _rec = _unit getVariable [CHECK_VARS select _slot, []];
    if (_rec isEqualTo []) exitWith {["--", "NOT MONITORED", false]};
    _rec params ["_value", "_at", ["_by", ""]];
    [
        [_value] call _format,
        format ["BY HAND %1 AGO%2", [_at] call FUNC(age), ["", " - " + toUpper _by] select (_by isNotEqualTo "")],
        false
    ]
};
// A hand reading of zero is a reading - no pulse, no breathing - and is shown
// as one. Only a device that has not produced a number yet shows "--".
private _fnc_number = {
    params ["_v"];
    str round _v
};
// ACE keeps blood pressure as [diastolic, systolic] (the cuff, and the hand
// check, which measureLocal takes from ACE); ACM's AED NIBP display is the
// other way round, [systolic, diastolic].
private _fnc_pressure = {
    params ["_v"];
    _v params [["_low", 0], ["_high", 0]];
    format ["%1/%2", round _high, round _low]
};
private _fnc_nibp = {
    params ["_v"];
    _v params [["_sys", 0], ["_dia", 0]];
    format ["%1/%2", round _sys, round _dia]
};

// THE TABLET IS AN EKG AND A PULSE OXIMETER (user, 2026-10-22: "assume the
// tablet is also an EKG and O2 pulse ox"): with no device on the man, his
// heart rate and SpO2 are read live from ACE medical as the tablet's own
// leads. A placed ACM device still wins, and a man ACE has not set up yet
// (no heart rate on him) falls back to the hand checks.

// --- heart rate -----------------------------------------------------------------
private _hr = switch (true) do {
    case (_oxArm > -1): {
        private _pr = round (_oxShown param [1, 0]);
        [[str _pr, "PULSE OX - LIVE", true], ["--", "PULSE OX - NO SIGNAL", false]] select (_pr isEqualTo 0)
    };
    case (_alive && {!isNil {_unit getVariable ACEV_HEART_RATE}}): {
        [str round (_unit getVariable [ACEV_HEART_RATE, 0]), "TABLET EKG - LIVE", true]
    };
    default {[0, _fnc_number] call _fnc_manual};
};

// --- blood pressure ---------------------------------------------------------------
private _bp = switch (true) do {
    case (_cuffArm > -1): {
        [[_unit getVariable [ACEV_BLOOD_PRESSURE, [0, 0]]] call _fnc_pressure, "CUFF - LIVE", true]
    };
    case (_aedCuff > -1): {
        private _nibp = _unit getVariable [ACMV_AED_NIBP, [0, 0]];
        [[[_nibp] call _fnc_nibp, "AED NIBP - LIVE", true], ["--", "AED NIBP - CYCLING", false]] select ((_nibp param [0, 0]) isEqualTo 0)
    };
    default {[1, _fnc_pressure] call _fnc_manual};
};

// --- SpO2 -----------------------------------------------------------------------
private _spo2 = switch (true) do {
    case (_oxArm > -1): {
        private _sat = round (_oxShown param [0, 0]);
        [[str _sat, "PULSE OX - LIVE", true], ["--", "PULSE OX - NO SIGNAL", false]] select (_sat isEqualTo 0)
    };
    case (_aedOx > -1): {
        private _sat = round (_unit getVariable [ACMV_AED_SPO2, 0]);
        [[str _sat, "AED - LIVE", true], ["--", "AED - NO SIGNAL", false]] select (_sat <= 0)
    };
    case (_alive && {!isNil {_unit getVariable ACEV_SPO2}}): {
        [str round (_unit getVariable [ACEV_SPO2, 0]), "TABLET PULSE OX - LIVE", true]
    };
    case (!_acm): {["--", "ACM NOT LOADED", false]};
    default {["--", "NOT MONITORED", false]};
};

// --- respiration rate --------------------------------------------------------------
private _rr = switch (true) do {
    case (!_acm): {["--", "ACM NOT LOADED", false]};
    case (_capno isEqualTo true): {
        private _rate = round (_unit getVariable [ACMV_AED_RR, 0]);
        [[str _rate, "CAPNOGRAPH - LIVE", true], ["--", "CAPNOGRAPH - NO SIGNAL", false]] select (_rate isEqualTo 0)
    };
    default {[2, _fnc_number] call _fnc_manual};
};

// A dead man has no vitals, and an old hand check under a "--" would read as
// if it had found nothing.
if (!_alive) then {
    {
        _x set [0, "--"];
        _x set [1, "DEAD"];
        _x set [2, false];
    } forEach [_hr, _bp, _spo2, _rr];
};

[
    ["HEART RATE", _hr # 0, "BPM", _hr # 1, _hr # 2],
    ["BLOOD PRESSURE", _bp # 0, "MMHG", _bp # 1, _bp # 2],
    ["SPO2", _spo2 # 0, "%", _spo2 # 1, _spo2 # 2],
    ["RESP RATE", _rr # 0, "/MIN", _rr # 1, _rr # 2]
]
