#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the nearest medical facility to a point - a CASEVAC's DEFAULT
 * destination (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4: "PATIENTS ABOARD -
 * DESTINATION?" answered DEFAULT, nearest medical). What the mod knows:
 *
 *   1. an object of the mission marked an ACE medical facility - the variable
 *      `ace_medical_isMedicalFacility` (the JMSB field hospital,
 *      jmfsb_logistics_fnc_doFieldHospital, or a mission's own) or its class's
 *      config property of the same name
 *   2. the terrain's own hospitals - map objects of type HOSPITAL
 *
 * The nearest of the first kind wins over any of the second; none of either:
 * [] - the provider decides (its base). Asked once per answer, never per frame.
 *
 * Arguments:
 * 0: From <ARRAY>
 *
 * Return Value:
 * [position [x, y, 0], what it is] or [] for none <ARRAY>
 *
 * Example:
 * [getPosATL _veh] call jmfsb_support_fnc_medicalNearest
 *
 * Public: Yes
 */

params [["_from", [], [[]]]];

if (count _from < 2) exitWith {[]};
_from = [_from select 0, _from select 1, 0];

private _fnc_point = {
    (getPosATL _this) params ["_px", "_py"];
    [_px, _py, 0]
};

// 1. THE MISSION'S OWN: a field hospital, a medical tent.
private _marked = (allMissionObjects "") select {
    alive _x && {(_x getVariable [MEDICAL_FACILITY_VAR, false]) isEqualTo true || {getNumber (configOf _x >> MEDICAL_FACILITY_VAR) > 0}}
};
if (_marked isNotEqualTo []) exitWith {
    private _byRange = _marked apply {[_x distance2D _from, _x]};
    _byRange sort true;
    [((_byRange select 0) select 1) call _fnc_point, MEDICAL_WORD_FIELD]
};

// 2. THE TERRAIN'S HOSPITALS, nearest first.
private _hospitals = nearestTerrainObjects [_from, MEDICAL_TERRAIN_TYPES, worldSize, true, true];
if (_hospitals isNotEqualTo []) exitWith {
    [(_hospitals select 0) call _fnc_point, MEDICAL_WORD_HOSPITAL]
};

[]
