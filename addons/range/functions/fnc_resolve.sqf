#include "..\script_component.hpp"
/*
 * Author: YonV
 * An object, or the object a mission variable name points at.
 *
 * Arguments:
 * 0: Object or variable name <OBJECT, STRING>
 *
 * Return Value:
 * Object, or objNull <OBJECT>
 *
 * Public: No
 */

params [["_ref", objNull, [objNull, ""]]];

if (_ref isEqualType "") then {
    _ref = missionNamespace getVariable [_ref, objNull];
};
if (_ref isEqualType objNull) then {_ref} else {objNull}
