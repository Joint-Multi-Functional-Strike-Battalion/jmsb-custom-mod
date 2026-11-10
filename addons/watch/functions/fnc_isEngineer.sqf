#include "script_component.hpp"
/*
 * Author: YonV
 * The engineer profile's gate (design: ACE engineer or EOD trait): ACE's
 * engineer level, ACE's EOD flag, or the vanilla engineer / explosive
 * specialist trait.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Is an engineer <BOOL>
 *
 * Example:
 * [player] call jmfsb_watch_fnc_isEngineer
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

(_unit getVariable ["ACE_isEngineer", 0]) isNotEqualTo 0
    || {_unit getVariable ["ACE_isEOD", false]}
    || {_unit getUnitTrait "engineer"}
    || {_unit getUnitTrait "explosiveSpecialist"}
