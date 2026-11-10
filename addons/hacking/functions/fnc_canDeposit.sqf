#include "script_component.hpp"
/*
 * Author: YonV
 * Carrying intel to bank into this drop?
 *
 * The action lives on the deployed case, so being in range is the engine's
 * problem rather than a distance test here - all that is left to ask is
 * whether the player actually has anything worth putting in it.
 *
 * Arguments:
 * 0: The drop <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value:
 * Show the action <BOOL>
 *
 * Public: No
 */

params [["_drop", objNull, [objNull]], ["_unit", objNull, [objNull]]];

!isNull _drop
&& {!isNull _unit}
&& {(items _unit) findIf {_x in INTEL_ITEMS} > -1}
