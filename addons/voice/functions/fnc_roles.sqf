#include "script_component.hpp"
/*
 * Author: JMSB
 * Role tags of a unit, for contacts and group adds:
 * SL - he leads his group; RTO - he holds the RTO job (FUNC(isRto), the one
 * RTO test); MEDIC - medic trait or ACE medic class;
 * HQ - his role description or group callsign names a headquarters.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Tags from "SL", "RTO", "MEDIC", "HQ" <ARRAY of STRINGs>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_roles
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};
private _tags = [];
private _role = toUpper roleDescription _unit;
private _callsign = toUpper groupId group _unit;

if (leader group _unit isEqualTo _unit) then {_tags pushBack TAG_SL};

if ([_unit] call FUNC(isRto)) then {_tags pushBack TAG_RTO};

if (_unit getUnitTrait "medic" || (_unit getVariable ["ace_medical_medicClass", 0]) > 0) then {_tags pushBack TAG_MEDIC};

if ((HQ_WORDS findIf {_x in _role || _x in _callsign}) >= 0) then {_tags pushBack TAG_HQ};

_tags
