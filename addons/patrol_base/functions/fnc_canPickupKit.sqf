#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a unit can pick a deployed kit object back up into its inventory.
 *
 * Arguments:
 * 0: Kit object <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * Can pick up <BOOL>
 *
 * Public: No
 */

params [["_object", objNull, [objNull]], ["_unit", objNull, [objNull]]];

private _item = getText (configOf _object >> "correspondingItem");

!isNull _object
&& {alive _unit}
&& {isNull objectParent _unit}
&& _item != ""
&& {_unit canAdd _item}
