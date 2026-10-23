#include "script_component.hpp"
/*
 * Author: JMSB
 * The patient page's status lines: blood type, blood volume, bleeding, pain,
 * airway, chest and cardiac rhythm.
 *
 * ACE gives the first four, ACM the last three; a line whose source is not
 * loaded says so rather than claiming CLEAR. The cardiac rhythm is an EKG
 * reading, so it is shown only while ACM's AED pads are on - the same rule as
 * the vitals (FUNC(readVitals)).
 *
 * Every variable read is published by its owner - see README - except ACE's
 * pain level, which is local to the patient's machine. A remote patient's PAIN
 * line shows ACE's published in-pain flag instead, and says the level is local.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Bleed grade from FUNC(patientState), -1 none <NUMBER>
 *
 * Return Value:
 * One entry per line: [label, value, note, hot] <ARRAY>
 *
 * Example:
 * [_unit, 2] call jmfsb_medic_fnc_readStatus
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_grade", -1, [0]]];

private _acm = GVAR(acm);
private _rows = [];

// --- blood ------------------------------------------------------------------------
_rows pushBack ["BLOOD TYPE", [_unit] call FUNC(bloodType), "DOG TAGS", false];

private _volume = _unit getVariable [ACEV_BLOOD_VOLUME, BLOOD_VOLUME_FULL];
private _class = _unit getVariable [ACEV_HEMORRHAGE, 0];
_rows pushBack [
    "BLOOD VOLUME",
    format ["%1 L", (_volume max 0) toFixed 1],
    ["", format ["CLASS %1 HEMORRHAGE", _class]] select (_class > 0),
    _class >= HEMORRHAGE_HOT
];

_rows pushBack ["BLEEDING", if (_grade < 0) then {"NONE"} else {BLEED_WORDS select _grade}, "", _grade >= BLEED_HEAVY];

if (local _unit) then {
    private _pain = _unit getVariable [ACEV_PAIN, 0];
    private _painStep = PAIN_STEPS findIf {_pain < _x};
    if (_painStep < 0) then {_painStep = count PAIN_STEPS};
    _rows pushBack ["PAIN", PAIN_WORDS select _painStep, "", _painStep >= (count PAIN_STEPS)];
} else {
    private _inPain = (_unit getVariable [ACEV_IN_PAIN, false]) isEqualTo true;
    _rows pushBack ["PAIN", PAIN_REMOTE_WORDS select _inPain, "LEVEL LOCAL ONLY", false];
};

if (!_acm) exitWith {
    {_rows pushBack [_x, "--", "ACM NOT LOADED", false]} forEach ["AIRWAY", "CHEST", "RHYTHM"];
    _rows
};

// --- airway -----------------------------------------------------------------------
private _airway = switch (true) do {
    case ((_unit getVariable [ACMV_VOMIT, 0]) > 0): {"OBSTRUCTED - VOMIT"};
    case ((_unit getVariable [ACMV_BLOOD_AIRWAY, 0]) > 0): {"OBSTRUCTED - BLOOD"};
    case ((_unit getVariable [ACMV_COLLAPSE, 0]) > 0): {"COLLAPSING"};
    default {"CLEAR"};
};
private _adjuncts = [_unit getVariable [ACMV_ORAL, ""], _unit getVariable [ACMV_NASAL, ""]] select {_x isEqualType "" && _x isNotEqualTo ""};
if (_unit getVariable [ACMV_SURGICAL, false]) then {_adjuncts pushBack "CRIC"};
_rows pushBack ["AIRWAY", _airway, _adjuncts joinString " / ", _airway isNotEqualTo "CLEAR"];

// --- chest ------------------------------------------------------------------------
private _chest = [];
private _ptx = _unit getVariable [ACMV_PTX, 0];
switch (true) do {
    case (_unit getVariable [ACMV_TPTX, false]): {_chest pushBack "TENSION PNEUMOTHORAX"};
    case (_ptx > 0): {_chest pushBack format ["PNEUMOTHORAX GR %1", _ptx]};
};
if ((_unit getVariable [ACMV_HTX, 0]) > 0) then {_chest pushBack "HEMOTHORAX"};
_rows pushBack [
    "CHEST",
    [_chest joinString " + ", "CLEAR"] select (_chest isEqualTo []),
    ["", "CHEST SEAL ON"] select (_unit getVariable [ACMV_CHEST_SEAL, false]),
    _chest isNotEqualTo []
];

// --- rhythm: an EKG reading - the AED's pads, else the tablet's own leads ---------
// THE TABLET IS AN EKG (user, 2026-10-22): ACM keeps a rhythm on every man,
// and the tablet reads it live whether or not pads are on him.
private _pads = _unit getVariable [ACMV_AED_PADS, false];
private _rhythm = if (_pads || {!isNil {_unit getVariable ACMV_RHYTHM}}) then {
    private _r = _unit getVariable [ACMV_RHYTHM, RHYTHM_SINUS];
    if !(_r isEqualType 0) then {_r = -1};
    private _word = "UNKNOWN";
    if (_r >= 0 && _r < count RHYTHMS) then {_word = RHYTHMS select _r};
    [_word, ["TABLET EKG - LIVE", "AED PADS - LIVE"] select _pads, _r isNotEqualTo RHYTHM_SINUS]
} else {
    ["--", "NOT MONITORED", false]
};
_rows pushBack (["RHYTHM"] + _rhythm);

_rows
