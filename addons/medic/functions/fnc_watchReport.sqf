#include "script_component.hpp"
/*
 * Author: YonV
 * The medical profile's REPORT: the unit's MIST card on the tablet, addressed
 * to MEDICAL.mist, filled from the patient (design: I wounds by body part,
 * S vitals at send time, T tourniquets with how long they have been on, and
 * IVs). ONE THREAD PER PATIENT: a MIST already filed for him ("MIST <name>",
 * in this player's index) is replied into; the first opens the thread.
 * M - what caused it - is the medic's to write; sending is his press. The
 * time and triage are kept for the stale warning (FUNC(watchAlerts)).
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_watchReport
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {isNil QEFUNC(tacpad,composeOpen)}) exitWith {false};

private _name = toUpper ([_unit] call FUNC(nameOf));
private _tqTimes = _unit getVariable [ACEV_TOURNIQUETS, []];
private _injuries = [];
private _treated = [];
{
    _x params ["_label", ["_open", 0], ["_bandaged", 0], "", "", "", ["_ivs", 0]];
    if (_open isNotEqualTo 0 || _bandaged isNotEqualTo 0) then {
        _injuries pushBack format ["%1: %2 open, %3 bandaged", _label, _open, _bandaged];
    };
    private _tq = _tqTimes param [_forEachIndex, 0];
    private _tqOn = if (_tq isEqualType 0) then {_tq > 0} else {false};
    if (_tqOn) then {
        _treated pushBack format ["TQ %1 %2 min", _label, floor ((CBA_missionTime - _tq) / 60)];
    };
    private _ivOn = if (_ivs isEqualType 0) then {_ivs > 0} else {false};
    if (_ivOn) then {_treated pushBack format ["IV %1", _label]};
} forEach ([_unit] call FUNC(readBody));

([_unit] call FUNC(readVitals)) params ["_hr", "_bp", "_spo2", "_rr"];
([_unit] call FUNC(patientState)) params ["_state"];
private _vitals = format ["%1 - HR %2, BP %3, SpO2 %4, RR %5", STATE_WORDS select _state, _hr # 1, _bp # 1, _spo2 # 1, _rr # 1];

// his thread, if there is one
private _thread = "";
{
    if ((_x getOrDefault ["templateId", ""]) isEqualTo MIST_TEMPLATE && {((_x getOrDefault ["subject", ""]) find format ["MIST %1 ", _name]) isEqualTo 0}) then {
        _thread = _x getOrDefault ["threadId", ""];
    };
} forEach (missionNamespace getVariable [QEGVAR(messaging,index), []]);

GVAR(mistSent) set [hashValue _unit, [CBA_missionTime, _unit getVariable [ACEV_TRIAGE, 0]]];
[_thread, MIST_TEMPLATE, false, [MIST_NET, ""] select (_thread isNotEqualTo ""), [
    ["Patient.A", _name],
    ["I.A", [_injuries joinString "; ", "none seen"] select (_injuries isEqualTo [])],
    ["S.A", _vitals],
    ["T.A", [_treated joinString "; ", "none"] select (_treated isEqualTo [])]
]] call EFUNC(tacpad,composeOpen)
