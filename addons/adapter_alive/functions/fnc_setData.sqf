#include "script_component.hpp"
/*
 * Author: YonV
 * Writes a jmfsb value to ALiVE's persistence store. See FUNC(getData).
 *
 * Arguments:
 * 0: Key <STRING>
 * 1: Value <ANY>
 *
 * Return Value:
 * Written <BOOL>
 *
 * Public: No
 */

params [["_key", "", [""]], "_value"];

if (_key isEqualTo "" || {isNil "ALiVE_fnc_setData"} || {isNil "_value"}) exitWith {false};

[_key, _value] call ALiVE_fnc_setData;
true
