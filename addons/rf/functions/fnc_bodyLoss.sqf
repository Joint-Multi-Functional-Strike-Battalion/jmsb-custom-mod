#include "script_component.hpp"
/*
 * Author: JMSB
 * The loss at one end of a link from how the set is carried: prone, or a
 * handheld inside a vehicle. A node whose object is the vehicle itself (a
 * vehicle set with its own mast) or a prop pays nothing.
 *
 * Arguments:
 * 0: Node object <OBJECT>
 *
 * Return Value:
 * Loss dB <NUMBER>
 *
 * Example:
 * [player] call jmfsb_rf_fnc_bodyLoss
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if !(_obj isKindOf "CAManBase") exitWith {0};
if (!isNull objectParent _obj) exitWith {GVAR(vehicleDb)};
if (stance _obj == "PRONE") exitWith {GVAR(proneDb)};
0
