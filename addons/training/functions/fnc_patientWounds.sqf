#include "script_component.hpp"
/*
 * Author: YonV
 * A preset's wounds, as [body part, ACE damage type, damage] rows (user,
 * 2026-11-07: presets plus a per-part page). The parts and the amounts vary
 * each time, so two LIGHT patients are not the same patient.
 *
 *     light     one limb wound, sometimes a second, light
 *     moderate  a limb and the torso, medium
 *     severe    two heavy limb blasts and a torso wound - goes unconscious
 *     arrest    severe, then cardiac arrest
 *     random    one of the four
 *
 * Arguments:
 * 0: Preset id from PRESETS <STRING>
 *
 * Return Value:
 * [rows, unconscious, cardiac arrest] <ARRAY>
 *
 * Example:
 * ["moderate"] call jmfsb_training_fnc_patientWounds
 *
 * Public: No
 */

params [["_preset", "light", [""]]];

if (_preset isEqualTo "random") then {_preset = selectRandom PRESET_RANDOM_FROM};

private _light = (WOUND_SEVERITY # 0) # 0;
private _medium = (WOUND_SEVERITY # 1) # 0;
private _heavy = (WOUND_SEVERITY # 2) # 0;
private _limbs = LIMBS call BIS_fnc_arrayShuffle;

switch (_preset) do {
    case "moderate": {
        [[[_limbs # 0, "bullet", _medium], ["body", selectRandom ["bullet", "stab"], _medium]], false, false]
    };
    case "severe": {
        [[[_limbs # 0, "explosive", _heavy], [_limbs # 1, "explosive", _heavy], ["body", "bullet", _medium]], true, false]
    };
    case "arrest": {
        [[[_limbs # 0, "explosive", _heavy], [_limbs # 1, "explosive", _heavy], ["body", "bullet", _heavy]], true, true]
    };
    default {
        private _rows = [[_limbs # 0, "bullet", _light]];
        if (random 1 < SECOND_WOUND_CHANCE) then {_rows pushBack [_limbs # 1, "punch", _light]};
        [_rows, false, false]
    };
}
