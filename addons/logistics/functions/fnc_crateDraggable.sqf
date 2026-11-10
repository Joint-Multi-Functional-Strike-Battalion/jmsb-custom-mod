#include "script_component.hpp"
/*
 * Author: YonV
 * Every machine, joiners too: a supply crate (FUNC(doSupplyCrate)) can be
 * dragged and carried. ACE's setters have local effect, so the server sends
 * this to every machine by remoteExec, JIP-tied to the crate (review L3);
 * a remote call from anyone but the server is dropped (review R1).
 *
 * Arguments:
 * 0: The crate <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate] remoteExecCall ["jmfsb_logistics_fnc_crateDraggable", 0, _crate]
 *
 * Public: No
 */

params [["_crate", objNull, [objNull]]];

if (isNull _crate) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("Logistics","crateDraggable refused: not from the server (machine %1)",remoteExecutedOwner);
};

[_crate, true] call ace_dragging_fnc_setDraggable;
[_crate, true] call ace_dragging_fnc_setCarryable;
