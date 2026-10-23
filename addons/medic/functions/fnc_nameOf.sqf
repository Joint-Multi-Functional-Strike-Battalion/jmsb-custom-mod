#include "script_component.hpp"
/*
 * Author: JMSB
 * A patient's name, dead or alive. The engine's `name` of a corpse can come
 * back as an error string; ACE keeps the name on the unit for exactly this, so
 * its getName is asked when it is loaded.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Name <STRING>
 *
 * Example:
 * [_unit] call jmfsb_medic_fnc_nameOf
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {""};

if (isNil "ace_common_fnc_getName") exitWith {name _unit};

[_unit, false, true] call ace_common_fnc_getName
