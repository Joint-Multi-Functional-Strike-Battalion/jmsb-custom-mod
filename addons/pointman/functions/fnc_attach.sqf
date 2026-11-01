#include "script_component.hpp"
/*
 * Author: JMSB
 * Hangs the route's drawing on one map control - the vanilla map's, or the
 * tablet's screen, which jmfsb_devices declares at the same idc. Once per
 * control: a flag on the control, so the route is drawn once however many
 * times the map opens.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [(findDisplay 12) displayCtrl 51] call jmfsb_pointman_fnc_attach
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]]];

if (isNull _map) exitWith {};
if (_map getVariable [QGVAR(attached), false]) exitWith {};
_map setVariable [QGVAR(attached), true];

_map ctrlAddEventHandler ["Draw", {_this call FUNC(draw)}];
