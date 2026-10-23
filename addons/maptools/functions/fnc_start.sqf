#include "script_component.hpp"
/*
 * Author: JMSB
 * Starts a map tool, or stops it if it is the one running - a toggle, which is
 * what the TOOLS panel's cells are. One tool at a time: starting one stops
 * whatever was taking clicks before it. Stopping never wipes a drawing; that
 * is FUNC(clear).
 *
 * ROUTE starts a new route. A route is planned in one go, and a second route
 * strung onto the end of the first is not a thing anybody wants.
 *
 * Arguments:
 * 0: Tool id: "ruler", "protractor", "mark", "grid", "viewshed" or "route" <STRING>
 *
 * Return Value:
 * The tool now running, "" for none <STRING>
 *
 * Example:
 * ["ruler"] call jmfsb_maptools_fnc_start
 *
 * Public: Yes
 */

params [["_tool", "", [""]]];

private _was = GVAR(tool);
[] call FUNC(stop);

if (_tool isEqualTo _was || {!(_tool in TOOLS_ALL)}) exitWith {""};

GVAR(tool) = _tool;

if (_tool isEqualTo TOOL_ROUTE) then {
    GVAR(route) = [];
};

_tool
