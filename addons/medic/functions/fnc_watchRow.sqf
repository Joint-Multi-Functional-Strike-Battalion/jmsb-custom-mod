#include "script_component.hpp"
/*
 * Author: YonV
 * The watch HUD's medical profile readout (docs/DESIGN_WATCH_HUD.json): one
 * patient as the world panel and the device panel show him. The colour and
 * word are his ACE triage card when one is set (T1 red, T2 yellow, T3 green,
 * T4 grey), else the suggested triage marked "?" (FUNC(triageSuggest)). Two
 * tiers: a medic (ACE medic class 2, or PAC Medic) reads HR and tourniquets
 * with the longest one's minutes, then BP and SpO2; everyone
 * else the CLS tier - bleeding in place of BP and SpO2. Readings are the
 * medic app's, device-gated.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * [name, state word, colour, [line 2, line 3], live] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_watchRow
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {["", "", [1, 1, 1, 1], [], false]};

([_unit] call FUNC(patientState)) params ["_state", "_heavy", "_grade"];
([_unit] call FUNC(readVitals)) params ["_hr", "_bp", "_spo2"];
private _tqs = {_x > 0} count (_unit getVariable [ACEV_TOURNIQUETS, []]);
private _bleed = ["NONE", BLEED_WORDS select _grade] select (_grade > -1);
if (_heavy) then {_bleed = _bleed + " !"};

// The card wins; with none set, the suggestion, marked "?" (FUNC(triageSuggest)).
private _triage = _unit getVariable [ACEV_TRIAGE, 0];
private _card = _triage in TRIAGE_LEVELS;
if (!_card) then {_triage = [_unit] call FUNC(triageSuggest)};
private _colour = if (_triage in TRIAGE_LEVELS) then {TRIAGE_COLOURS # (_triage - 1)} else {["swatchGreen"] call EFUNC(tacpad,theme)};
private _word = STATE_WORDS select _state;
if (_triage in TRIAGE_LEVELS) then {_word = format ["T%1%2 %3", _triage, ["?", ""] select _card, _word]};

// the longest tourniquet, in minutes (design row_line_2). No MIST age (user,
// 2026-11-08: "what is the word mist for"): the MIST STALE alert says it.
private _tqLong = 0;
{
    private _on = if (_x isEqualType 0) then {_x > 0} else {false};
    if (_on) then {_tqLong = _tqLong max (CBA_missionTime - _x)};
} forEach (_unit getVariable [ACEV_TOURNIQUETS, []]);

private _medic = (player getVariable [ACEV_MEDIC_CLASS, 0]) >= 2 || {"MED" in (player getVariable [QEGVAR(pac,skillTags), []])};
[
    toUpper ([_unit] call FUNC(nameOf)),
    _word,
    _colour,
    [
        format ["HR %1   TQ %2%3", _hr # 1, _tqs, ["", format [" %1 MIN", floor (_tqLong / 60)]] select (_tqs > 0)],
        [format ["BLEED %1", _bleed], format ["BP %1  SPO2 %2", _bp # 1, _spo2 # 1]] select _medic
    ],
    alive _unit
]
