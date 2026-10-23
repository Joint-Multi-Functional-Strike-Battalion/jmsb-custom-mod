#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every CLIENT_TICK_S: hangs the EW layer (FUNC(mapDraw)) on the map
 * of both hosts - the vanilla map (display 12, control 51) and, in a device
 * mode, the device host's own map (the tacpad host display's IDC_HOST_MAP).
 * Once per control: the flag lives on the control, so a host display that
 * is rebuilt gets the layer again.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [LINKFUNC(mapHook), CLIENT_TICK_S, []] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

private _maps = [findDisplay MAP_DISPLAY displayCtrl MAP_CONTROL];
if (HOST_DEVICE) then {
    _maps pushBack ((HOST_DISPLAY) displayCtrl IDC_HOST_MAP);
};

{
    if (isNull _x || {_x getVariable [QGVAR(drawHung), false]}) then {continue};
    _x setVariable [QGVAR(drawHung), true];
    _x ctrlAddEventHandler ["Draw", {_this call FUNC(mapDraw)}];
} forEach _maps;
