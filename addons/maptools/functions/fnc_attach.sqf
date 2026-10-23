#include "script_component.hpp"
/*
 * Author: JMSB
 * Hangs the map tools on one map control: the drawing and the three mouse
 * events the tools read. Works on any map control - the vanilla map's, and the
 * tablet's screen, which jmfsb_devices declares at the same idc on purpose.
 *
 * ONCE PER CONTROL. A flag on the control, not on the tool: a handler added on
 * every panel build is a handler that draws every ruler as many times as the
 * panel has been built.
 *
 * The display it sits on stops the tool when it unloads - the tablet's dialog
 * closing is the tablet's map closing. The vanilla map never unloads; its
 * close is the Map mission event in XEH_postInit.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [(findDisplay 12) displayCtrl 51] call jmfsb_maptools_fnc_attach
 *
 * Public: Yes
 */

params [["_map", controlNull, [controlNull]]];

if (isNull _map) exitWith {};
if (_map getVariable [QGVAR(attached), false]) exitWith {};
_map setVariable [QGVAR(attached), true];

_map ctrlAddEventHandler ["Draw", {_this call FUNC(draw)}];
_map ctrlAddEventHandler ["MouseButtonDown", {_this call FUNC(mouseDown)}];
_map ctrlAddEventHandler ["MouseButtonUp", {_this call FUNC(mouseUp)}];
_map ctrlAddEventHandler ["MouseMoving", {_this call FUNC(mouseMove)}];

private _display = ctrlParent _map;
if (!isNull _display && {!(_display getVariable [QGVAR(unloadWired), false])}) then {
    _display setVariable [QGVAR(unloadWired), true];
    _display displayAddEventHandler ["Unload", {[] call FUNC(stop)}];
};
