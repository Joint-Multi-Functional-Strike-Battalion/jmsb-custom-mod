#include "script_component.hpp"
/*
 * Author: JMSB
 * The debug overlay, on the map's Draw event: a line between every pair of
 * directly linked nodes, red at quality 0 to green at 1. The server publishes
 * the links (jmfsb_rf_debugEdges) only while the debug setting is on; the
 * line ends follow the objects live.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_rf_fnc_drawDebug}]
 *
 * Public: No
 */

params ["_map"];

if (!GVAR(debugOverlay)) exitWith {};

{
    _x params ["", "_a", "_b", "_q"];
    if (isNull _a || {isNull _b}) then {continue};
    _map drawLine [getPosVisual _a, getPosVisual _b, [1 - _q, _q, 0, DEBUG_LINE_ALPHA]];
} forEach GVAR(debugEdges);
