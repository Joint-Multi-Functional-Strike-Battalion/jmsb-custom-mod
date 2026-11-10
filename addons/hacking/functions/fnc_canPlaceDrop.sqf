#include "script_component.hpp"
/*
 * Author: YonV
 * Carrying a packed drop case, and on your feet to put it down?
 *
 * Arguments:
 * 0: The player <OBJECT>
 *
 * Return Value:
 * Show the action <BOOL>
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

!isNull _unit
&& {alive _unit}
&& {QGVAR(dropItem) in (items _unit)}
&& {isNull objectParent _unit}
