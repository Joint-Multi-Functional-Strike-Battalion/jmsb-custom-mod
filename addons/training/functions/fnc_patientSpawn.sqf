#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a training patient on a stretcher (user, 2026-11-07: it replaces the
 * old medical simulator; the patient is a real casualty the medics treat, and
 * he shows in their tablet's medical app - on its NEARBY tab, since he is in
 * nobody's squad). Server only, raised from TAC//TRAINING.
 *
 * The patient is a man of the trainer's own class and side, unarmed, captive
 * and still, lying on the stretcher. His wounds go on through ACE medical,
 * where he is local (here): a preset's (FUNC(patientWounds)) or the trainer's
 * own rows. A patient already on the stretcher is removed first.
 *
 * Arguments:
 * 0: Stretcher <OBJECT>
 * 1: Preset id from PRESETS, "custom" for the rows <STRING>
 * 2: Custom rows [[body part, ACE damage type, damage], ...] <ARRAY>
 * 3: The trainer <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_stretcher, "severe", [], player] call jmfsb_training_fnc_patientSpawn
 *
 * Public: No
 */

params [["_stretcher", objNull, [objNull]], ["_preset", "light", [""]], ["_custom", [], [[]]], ["_trainer", objNull, [objNull]]];

if (!isServer || {isNull _stretcher} || {isNull _trainer}) exitWith {};

[_stretcher] call FUNC(patientClear);

private _wounds = if (_preset isEqualTo "custom") then {
    // custom: unconscious when any wound is heavy; arrest is a preset's
    private _heavy = (WOUND_SEVERITY # 2) # 0;
    [_custom, (_custom findIf {(_x param [2, 0]) >= _heavy}) >= 0, false]
} else {
    [_preset] call FUNC(patientWounds)
};
_wounds params ["_rows", "_unconscious", "_arrest"];

private _grp = createGroup [side group _trainer, true];
private _unit = _grp createUnit [typeOf _trainer, getPosATL _stretcher, [], 0, "CAN_COLLIDE"];
removeAllWeapons _unit;
_unit setCaptive true;
_unit allowFleeing 0;
{_unit disableAI _x} forEach ["MOVE", "PATH", "TARGET", "AUTOTARGET", "AUTOCOMBAT", "FSM"];
_unit setDir getDir _stretcher;
_unit setPosASL ((getPosASL _stretcher) vectorAdd [0, 0, STRETCHER_LIFT]);
[_unit, PATIENT_ANIM] remoteExec ["switchMove", 0];
_unit setVariable [QGVAR(stretcher), _stretcher, true];
_stretcher setVariable [QGVAR(patient), _unit, true];

if (isClass (configFile >> "CfgPatches" >> "ace_medical")) then {
    {
        _x params [["_part", "body"], ["_type", "bullet"], ["_damage", 0]];
        if (_type isNotEqualTo "" && _damage > 0) then {
            [_unit, _damage, _part, _type] call ace_medical_fnc_addDamageToUnit;
        };
    } forEach _rows;
    if (_unconscious) then {[_unit, true] call ace_medical_fnc_setUnconscious};
    if (_arrest) then {
        [{["ace_medical_FatalVitals", _this] call CBA_fnc_localEvent}, _unit, ARREST_DELAY] call CBA_fnc_waitAndExecute;
    };
} else {
    _unit setDamage (((_rows apply {_x param [2, 0]}) call BIS_fnc_arithmeticMean) min 0.9);
};

INFO_3("training patient on %1: %2 (%3 wounds)",_stretcher,_preset,count _rows);
