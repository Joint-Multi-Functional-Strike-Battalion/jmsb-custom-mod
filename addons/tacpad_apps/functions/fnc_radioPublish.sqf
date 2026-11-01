#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the local player's active voice net where everyone else's squad table
 * and target card can read it: the name (QGVAR(radio)), on the unit he
 * controls (CBA_fnc_currentUnit).
 *
 * ONLY WHEN IT CHANGES. A public variable is a network message, and sixteen
 * players broadcasting an unchanged string every few seconds is sixteen messages
 * a second saying nothing. Almost every tick is a no-op.
 *
 * Arguments (CBA per-frame handler):
 * 0: Arguments <ARRAY> - unused
 * 1: Handle <NUMBER> - unused
 *
 * Return Value:
 * None
 *
 * Example:
 * [LINKFUNC(radioPublish), 5, []] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params ["", ""];

// The unit the player is in now - a Zeus-controlled one included - is the one
// the squad table and target card look at (review L4).
private _unit = call CBA_fnc_currentUnit;
if (isNull _unit) exitWith {};

private _net = [] call FUNC(radioState);
if (_net isEqualTo (_unit getVariable [QGVAR(radio), ""])) exitWith {};

_unit setVariable [QGVAR(radio), _net, true];
