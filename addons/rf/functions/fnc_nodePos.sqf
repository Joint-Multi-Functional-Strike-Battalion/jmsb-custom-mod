#include "script_component.hpp"
/*
 * Author: JMSB
 * Where a node's antenna is, ASL: a man's eyes (or his vehicle's, when he is
 * in one), otherwise a little above the object. Height above ground is not
 * in the budget yet (docs/DESIGN_RF.md open item 1); this only keeps the
 * terrain and clutter casts out of the ground.
 *
 * Arguments:
 * 0: Node object <OBJECT>
 *
 * Return Value:
 * Position ASL <ARRAY>
 *
 * Example:
 * [player] call jmfsb_rf_fnc_nodePos
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (_obj isKindOf "CAManBase") exitWith {eyePos _obj};
(getPosASL _obj) vectorAdd [0, 0, PROP_ANTENNA_M]
