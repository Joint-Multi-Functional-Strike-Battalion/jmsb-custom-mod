#include "script_component.hpp"
/*
 * Author: YonV
 * Who may create, edit and delete C2 measures (design c2_app): team leads and
 * ATLs - the role's isLeader. The creator is one of them by that rule.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * May edit <BOOL>
 *
 * Example:
 * [player] call jmfsb_c2_fnc_canEdit
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

!isNull _unit && {(_unit getVariable ["isLeader", false]) isEqualTo true}
