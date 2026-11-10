#include "script_component.hpp"
/*
 * Author: YonV
 * The self-aid profile's readout - the player's own state, for everyone
 * (design: bleeding, pain, conscious, tourniquets). Read off ACE medical's
 * public unit variables; without ACE medical it says so.
 *
 * Arguments:
 * 0: The player <OBJECT>
 *
 * Return Value:
 * [name, state word, colour, [line 2, line 3], live] <ARRAY>
 *
 * Example:
 * [player] call jmfsb_watch_fnc_selfAidRow
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if !(isClass (configFile >> "CfgPatches" >> "ace_medical")) exitWith {["YOU", "NO MEDICAL", COLOUR_GREY, [], false]};

private _bleeding = (_unit getVariable ["ace_medical_woundBleeding", 0]) > 0;
private _pain = _unit getVariable ["ace_medical_pain", 0];
private _awake = !(_unit getVariable ["ACE_isUnconscious", false]);
private _tqs = {_x > 0} count (_unit getVariable ["ace_medical_tourniquets", []]);

private _word = switch (true) do {
    case (!_awake): {"UNCONSCIOUS"};
    case (_bleeding): {"BLEEDING"};
    case (_pain > PAIN_HURT): {"IN PAIN"};
    default {"OK"};
};
[
    "YOU", _word,
    [COLOUR_GREEN, [COLOUR_AMBER, COLOUR_RED] select (_bleeding || !_awake)] select (_word isNotEqualTo "OK"),
    [format ["BLEEDING %1   PAIN %2%3", ["NO", "YES"] select _bleeding, round (_pain * 100), "%"], format ["TOURNIQUETS %1", _tqs]],
    true
]
